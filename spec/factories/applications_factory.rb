FactoryGirl.define do
  factory :empty_application, class: Arkaan::OAuth::Application do
    factory :application do
      name 'test application'
      key 'test_key'
      premium true
      association :creator, factory: :account, strategy: :build
    end
  end
end