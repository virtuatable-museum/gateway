module Controllers
  # Factory-like class dynamically producing controllers for each declared micro-service.
  # @author Vincent Courtois <courtois.vincent@outlook.com>
  class MicroService < Sinatra::Base

    # Creates a dynamic class for the given service to map it on the gateway.
    # @param service [Arkaan::Monitorjng::Service] the service to create the controller for, used to compute the routes and mapping path.
    # @return [Sinatra::Base] a sinatra base class controller to map on the service path.
    def self::build_from(service)
      
      # Each controller class is dynamically created from a stored service (instance of Arkaan::Monitoring::Service)
      # it's then mapped from the service path.
      # @author Vincent Courtois <courtois.vincent@outlook.com>
      controllerClass = Class.new(Sinatra::Base) do
        # @!attribute [r] forward_tunnel
        #   @return [Faraday] the connection to the instance of the service on which you forward the requests.
        attr_reader :tunnel_to_service
        # @!attribute [r] instance
        #   @return [Arkaan::Monitoring::Instance] the instance of the service on when the gateway forwards the request.
        # @todo Make the choice of the instance dynamic for each request, not at creation.
        attr_reader :instance
        # @!attribute [r] gateway_token
        #   @return [String] the current token of the gateway to enrich the forwarded request with.
        attr_reader :gateway_token
        # @!attribute [r] stored_service
        #   @return [Arkaan::Monitoring::Service] the stored service representing this controller in the database.
        attr_reader :stored_service

        # Each controller is instanciated by giving him the service so it can store it.
        # @param service [Arkaan::Monitoring::Service] the service stored in the database.
        def initialize(service)
          super
          @gateway_token = Utils::Seeder.instance.create_gateway.token
          @instance = service.instances.sample
          @stored_service = service
          @tunnel_to_service = Faraday.new(instance.url) do |faraday|
            faraday.request  :url_encoded
            faraday.response :logger
            faraday.adapter  Faraday.default_adapter
          end

          # Here is the big piece. Each route is declared from the routes stored in the database, forwarding it automatically
          # to the route with the same method and URL on the service, forwarding parameters and body as they are, just adding the
          # gateway token.
          stored_service.routes.each do |route|
            self.class.public_send(route.verb, route.path) do
              stored_service.reload

              check_service_activity
              check_instances_availability
              check_route_activity(route)
              check_application_key
              check_application_existence
              
              if route.authenticated
                check_session_id
                session = check_session_existence
                check_session_validity(session)
                check_session_access(session, route)
              end
                  
              forwarded_to_service = forward_to_service(request)
              halt forwarded_to_service.status, forwarded_to_service.body
            end
          end
        end

        # Checks if the service is currently marked 'active' and halts if not. 
        def check_service_activity
          halt 400, {message: 'inactive_service'}.to_json if !stored_service.active?      
        end

        # Checks if any instance is available on the service, halts if not.
        def check_instances_availability
          halt 400, {message: 'no_instance_available'}.to_json if stored_service.instances.active.empty?
        end

        # Checks if the route is currently marked 'active', halts if not.
        # @param route [Arkaan::Monitoring::Route] the route to check the inactivity of.
        def check_route_activity(route)
          halt 400, {message: 'inactive_route'}.to_json if !route.active?
        end

        # Checks if the application key is given in the parameters, halts if not.
        def check_application_key
          halt 400, {message: 'missing.app_key'}.to_json if application_key.nil?
        end

        # Checks if the session unique identifier is given in the parameters, halts if not.
        def check_session_id
          halt 400, {message: 'missing.session_id'}.to_json if session_id.nil?
        end

        # Checks if the application linked to the application key exists, halts if not.
        def check_application_existence
          application = Arkaan::OAuth::Application.where(key: application_key).first
          halt 404, {message: 'application_not_found'}.to_json if application.nil?
        end

        # Checks if the session linked to the session identifier exists, halts if not.
        # @return [Arkaan::Authentication::Session] the session linked to this identifier for further checks.
        def check_session_existence
          session = Arkaan::Authentication::Session.where(id: session_id).first
          halt 404, {message: 'session_not_found'}.to_json if session.nil?
          return session
        end

        # Checks if the session is valid (not currently expired), halts if it's expired.
        # @param session [Arkaan::Authentication::Session] the session to check the validity of.
        def check_session_validity(session)
          expiration_date = session.created_at.strftime('%s').to_i + session.expiration
          halt 422, {message: 'invalid_session'}.to_json if expiration_date < DateTime.now.strftime('%s').to_i
        end

        # Checks if the account linked to the session can have access to this route, halts if not.
        # @param session [Arkaan::Authentication::Session] the linked to the user you want to check privileges.
        # @param route [Arkaan::Monitoring::Route] the route to check the privilege of the user on.
        def check_session_access(session, route)
          authorized = session.account.groups.map(&:route_ids).flatten.include?(route.id)
          halt 401, {message: 'unauthorized'}.to_json if !authorized
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
          tunnel_to_service.public_send(forwarded_to_service.env['REQUEST_METHOD'].downcase) do |req|
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
      end

      return controllerClass.new(service)
    end
  end
end