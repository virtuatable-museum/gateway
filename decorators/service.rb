module Decorators
  class Service < Draper::Decorator
    delegate_all

    def forward(request)
      verb = request.env['REQUEST_METHOD'].downcase
      Faraday.new(url: object.instances.sample.url).send(verb, request.env['REQUEST_PATH'])
    end
  end
end