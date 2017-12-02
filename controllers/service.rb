module Controllers

  # This controller is instanciated for each service of the suite.
  # @author Vincent Courtois <courtois.vincent@outlook.com>
  class Service < Sinatra::Base

    # @!attribute [rw] service
    #   @return [Arkaan::Monitoring::Service] the service associated to this controller
    attr_reader :service
    # @!attribute [rw] instance
    #   @return [Arkaan::Monitoring::Instance] the deployed instance of the service used to make requests.
    attr_reader :instance
    # @!attribute [rw] connection
    #   @return [Faraday] the faraday connection to make requests on the instance of the service.
    attr_reader :connection

    # Builds the controller with the given service.
    # @param [Arkaan::Monitoring::Service] the service to bind to the controller
    def initialize(service)
      super
      @service = service
      @instance = service.instances.sample
      @connection = Faraday.new(url: instance.url) do |faraday|
        faraday.request  :url_encoded
        faraday.response :logger
        faraday.adapter  Faraday.default_adapter
      end
    end

    post '/' do
      @body = request.body.read.to_s rescue {}.to_json
      params[:token] = Utils::Seeder.instance.create_gateway.token
      @response = connection.post do |forward|
        forward.url '/', params
        forward.body = @body
        forward.headers['Content-Type'] = 'application/json'
        forward.options.timeout = 5
        forward.options.open_timeout = 2
      end
      status @response.status
      body @response.body
    end
  end
end