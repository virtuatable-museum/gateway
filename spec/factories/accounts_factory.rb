FactoryGirl.define do
  factory :empty_account, class: Arkaan::Account do
    factory :account do
      username  'Babausse'
      password  'password'
      firstname 'Vincent'
      lastname  'Courtois'
      email     'courtois.vincent@outlook.com'
      birthdate DateTime.new(2000, 1, 1)
      password_confirmation 'password'
    end
  end
end