FactoryGirl.define do
  factory :empty_service, class: Arkaan::Monitoring::Service do
    factory :service do
      key 'test'
      path '/test'
      premium true

      after :create do |evaluator, service|
        service.routes = [
          Arkaan::Monitoring::Route.new(path: '/first', premium: true, verb: 'get'),
          Arkaan::Monitoring::Route.new(path: '/second/:id', premium: true, verb: 'get'),
          Arkaan::Monitoring::Route.new(path: '/third', premium: true, verb: 'post'),
          Arkaan::Monitoring::Route.new(path: '/fourth/:id', premium: true, verb: 'put'),
          Arkaan::Monitoring::Route.new(path: '/fifth/:id', premium: true, verb: 'delete')
        ]
        service.instances = [
          Arkaan::Monitoring::Instance.new(url: 'https://service.com/', running: true)
        ]
        service.save!
      end
    end
  end
end