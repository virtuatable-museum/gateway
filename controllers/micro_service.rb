module Controllers
  # Factory-like class dynamically producing controllers for each declared micro-service.
  # @author Vincent Courtois <courtois.vincent@outlook.com>
  class MicroService

    # Creates a dynamic class for the given service to map it on the gateway.
    # @param service [Arkaan::Monitorjng::Service] the service to create the controller for, used to compute the routes and mapping path.
    # @return [Sinatra::Base] a sinatra base class controller to map on the service path.
    def self::build_from(service)
      
      # Each controller class is dynamically created from a stored service (instance of Arkaan::Monitoring::Service)
      # it's then mapped from the service path.
      # @author Vincent Courtois <courtois.vincent@outlook.com>
      controllerClass = Class.new(Sinatra::Base) do
        register Sinatra::ConfigFile
        helpers Sinatra::CustomLogger

        configure do
          Dir.mkdir('log') if !File.exists?('log')
          Logger.class_eval { alias :write :'<<' }
          common_logs = Logger.new('log/common.log', 'weekly', level: Logger::INFO)
          set :logger, common_logs
          use Rack::CommonLogger, common_logs
        end

        # @!attribute [r] gateway_token
        #   @return [String] the current token of the gateway to enrich the forwarded request with.
        attr_reader :gateway_token
        # @!attribute [r] stored_service
        #   @return [Arkaan::Monitoring::Service] the stored service representing this controller in the database.
        attr_reader :stored_service
        # @!attribute [r] stored_self
        #   @return [Arkaan::Monitoring::Gateway] the stored gateway currently running as this application instance.
        attr_reader :stored_self

        config_file File.join(File.dirname(__FILE__), '..', 'config', 'errors.yml')

        # Each controller is instanciated by giving him the service so it can store it.
        # @param service [Arkaan::Monitoring::Service] the service stored in the database.
        def initialize(service)
          super
          @gateway_token = Utils::Seeder.instance.create_gateway.token
          @stored_service = service
          @stored_self = Utils::Seeder.instance.create_gateway

          # Here is the big piece. Each route is declared from the routes stored in the database, forwarding it automatically
          # to the route with the same method and URL on the service, forwarding parameters and body as they are, just adding the
          # gateway token.
          stored_service.routes.each do |route|
            logger.info("Démarrage de la route #{route.verb} /#{stored_service.key}#{route.path}")

            self.class.public_send(route.verb, route.path) do
              stored_service.reload
              route.reload

              initialize_logs

              check_service_activity
              check_instances_availability
              check_route_activity(route)
              check_application_key
              check_application_existence

              if route.authenticated
                check_session_id
                session = check_session_existence
                check_session_access(session, route)
              end
                  
              forwarded_to_service = forward_to_service(request)
              halt forwarded_to_service.status, forwarded_to_service.body
            end
          end
        end

        def initialize_logs
          error_log = ::File.new("log/error.log","a+")
          error_log.sync = true
          env["rack.errors"] = error_log
        end

        # Checks if the service is currently marked 'active' and halts if not. 
        def check_service_activity
          custom_error(400, 'common.service.inactive') if !stored_service.active?      
        end

        # Checks if any instance is available on the service, halts if not.
        def check_instances_availability
          custom_error(400, 'common.instance.unavailable') if stored_service.instances.where(running: true, active: true).empty?
        end

        # Checks if the route is currently marked 'active', halts if not.
        # @param route [Arkaan::Monitoring::Route] the route to check the inactivity of.
        def check_route_activity(route)
          custom_error(400, 'common.route.inactive') if !route.active?
        end

        # Checks if the application key is given in the parameters, halts if not.
        def check_application_key
          custom_error(400, 'common.app_key.required') if application_key.nil?
        end

        # Checks if the session unique identifier is given in the parameters, halts if not.
        def check_session_id
          custom_error(400, 'common.session_id.required') if session_id.nil?
        end

        # Checks if the application linked to the application key exists, halts if not.
        def check_application_existence
          application = Arkaan::OAuth::Application.where(key: application_key).first
          custom_error(404, 'common.app_key.unknown') if application.nil?
        end

        # Checks if the session linked to the session identifier exists, halts if not.
        # @return [Arkaan::Authentication::Session] the session linked to this identifier for further checks.
        def check_session_existence
          session = Arkaan::Authentication::Session.where(token: session_id).first
          custom_error(404, 'common.session_id.unknown') if session.nil?
          return session
        end

        # Checks if the account linked to the session can have access to this route, halts if not.
        # @param session [Arkaan::Authentication::Session] the linked to the user you want to check privileges.
        # @param route [Arkaan::Monitoring::Route] the route to check the privilege of the user on.
        def check_session_access(session, route)
          authorized = session.account.groups.map(&:route_ids).flatten.include?(route.id)
          custom_error(403, 'common.session_id.forbidden') if !authorized
        end

        # Forwards a request to the dedicated micro service and returns the response it gave.
        # @param forwarded_to_service [Request] the request the user made on the gateway.
        # @return [Response] the faraday response of the micro service for this request.
        def forward_to_service(forwarded_to_service)
          parameters = request.env['rack.request.query_hash']
          complete_body = parsed_body
          if parameters != {}
            parameters['token'] = gateway_token
          else
            complete_body['token'] = gateway_token
          end

          # require 'pry'; binding.pry
          get_connection.public_send(forwarded_to_service.env['REQUEST_METHOD'].downcase) do |req|
            req.url "#{stored_service.path}#{forwarded_to_service.path_info}", parameters || {}
            req.body = complete_body.to_json
            req.headers['Content-Type'] = 'application/json'
            req.options.timeout = 20
            req.options.open_timeout = 20
          end
        end

        # Gets the application key as a string, extracting it from either the query parameters or the parsed body.
        # @return [String, NilClass] the application key as a string, or nil if it was not given.
        def application_key
          return params['app_key'] || parsed_body['app_key'] || nil
        end

        # Gets the current session unique identifier as a BSON token.
        # @return [BSON::ObjectId, NilClass] the unique identifier for the session as an object ID
        def session_id
          return params['session_id'] || parsed_body['session_id'] || nil
        end

        # Returns the current parsed body as a hash, empty if there was none.
        # @return [Hash] the body given with the request parsed from a JSON formatted string.
        def parsed_body
          tmp_body = JSON.parse(request.body.read.to_s) rescue {}
          request.body.rewind
          return tmp_body
        end

        # Halts the application and creates the returned body from the parameters and the errors config file.
        # @param status [Integer] the HTTP status to halt the application with.
        # @param path [String] the path in the configuration file to access the URL.
        def custom_error(status, path)
          route, field, error = path.split('.')
          docs = settings.errors[route][field][error] rescue ''
          halt status, {status: status, field: field, error: error, docs: settings.errors[route][field][error]}.to_json
        end

        # Gets an instance from the service, regarding it's test mode value.
        # @param service [Arkaan::Monitoring::Service] the service to get an instance from.
        # @return [Arkaan::Monitoring::Instance] the instance to make the queries on.
        def get_instance_from(service)
          criteria = (service.test_mode && ENV['TEST_MODE']) ? {enum_type: :local} : {:enum_type.ne => :local}
          return service.instances.where(criteria).first
        end

        # Creates a faraday connection to either a random instance, or the desired instance in the service.
        # @return [Faraday] a faraday connection to forward the request into.
        def get_connection
          return Faraday.new(get_instance(params['instance_id']).url) do |faraday|
            faraday.request  :url_encoded
            faraday.response :logger
            faraday.adapter  Faraday.default_adapter
          end
        end

        # Gets the instance from the instance_id given in parameter, if sh'e up and running.
        # @param instance_id [String] the unique identifier of the instance to get.
        # @return [Arkaan::Monitoring::Instance] an instance to forward the request to.
        def get_instance(instance_id = nil)
          parameters = {
            running: true,
            active: true
          }
          parameters[:_id] = params['instance_id'] if params.has_key?('instance_id')
          if stored_self.type_local?
            local_instances = stored_service.instances.all.to_a.select { |instance| instance.type_local? }
            instance = local_instances.first
            instance = stored_service.instances.where({running: true, active: true}).first if instance.nil?
            return instance
          else
            return stored_service.instances.where(parameters).first
          end
        end
      end

      return controllerClass.new(service)
    end
  end
end