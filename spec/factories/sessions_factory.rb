FactoryGirl.define do
  factory :empty_session, class: Arkaan::Authentication::Session do
    association :account, factory: :account, strategy: :build

    factory :valid_session do
      token 'valid_session'
      created_at DateTime.now
    end
    factory :invalid_session do
      token 'invalid_session'
      created_at DateTime.now - 7200
    end
  end
end