module Controllers
  class Service < Sinatra::Base
    register Sinatra::MultiRoute

    attr_accessor :decorator

    def initialize(service)
      super
      @decorator = Decorators::Service.new(service)
    end

    route :get, :post, '/' do
      forward
    end

    route :get, :post, :put, '/:id' do
      forward
    end

    private

    def forward
      forwarded = decorator.forward(request)
      status forwarded.status
      body forwarded.body
    end
  end
end