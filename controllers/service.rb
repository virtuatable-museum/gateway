module Controllers
  class Service < Sinatra::Base

    attr_accessor :decorator, :forwarded

    def initialize(service)
      super
      @decorator = Decorators::Service.new(service)
    end

    before do
      @forwarded = decorator.forward(request)
    end

    get '/' do
      status forwarded.status
      body forwarded.body
    end
  end
end