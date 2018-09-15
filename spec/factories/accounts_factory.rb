FactoryGirl.define do
  factory :empty_account, class: Arkaan::Account do
    factory :account do
      username  'Babausse'
      password  'password'
      firstname 'Vincent'
      lastname  'Courtois'
      email     'courtois.vincent@outlook.com'
      password_confirmation 'password'
    end
  end
end