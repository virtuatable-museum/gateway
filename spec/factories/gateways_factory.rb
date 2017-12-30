FactoryGirl.define do
  factory :empty_gateway, class: Arkaan::Monitoring::Gateway do
    factory :gateway do
      url 'https://gateway.com/'
      diagnostic '/anything'
      token 'test_token'
      running false
      active false
    end
  end
end