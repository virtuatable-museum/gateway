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
              @parsed_body = JSON.parse(request.body.read.to_s) rescue {}
              application_key = parse_application_key
              if application_key.nil?
                halt 400, {message: 'bad_request'}.to_json
              else
                if Arkaan::OAuth::Application.where(key: application_key).first.nil?
                  halt 404, {message: 'application_not_found'}.to_json
                else
                  forwarded_to_service = forward_to_service(request)
                  halt forwarded_to_service.status, forwarded_to_service.body
                end
              end
            end
          end
        end

        # Forwards a request to the dedicated micro service and returns the response it gave.
        # @param forwarded_to_service [Request] the request the user made on the gateway.
        # @return [Response] the faraday response of the micro service for this request.
        def forward_to_service(forwarded_to_service)
          parameters = request.env['rack.request.query_hash']
          if parameters != {}
            parameters['token'] = gateway_token
          else
            @parsed_body['token'] = gateway_token
          end
          tunnel_to_service.public_send(forwarded_to_service.env['REQUEST_METHOD'].downcase) do |req|
            req.url "#{stored_service.path}#{forwarded_to_service.path_info}", parameters || {}
            req.body = @parsed_body.to_json
            req.headers['Content-Type'] = 'application/json'
            req.options.timeout = 5
            req.options.open_timeout = 2
          end
        end

        # Gets the application key as a string, extracting it from either the query parameters or the parsed body.
        # @return [String, NilClass] the application key as a string, or nil if it was not given.
        def parse_application_key
          return params['app_key'] || @parsed_body['app_key'] || nil
        end
      end
      return controllerClass.new(service)
    end
  end
end