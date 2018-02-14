FactoryGirl.define do
  factory :empty_group, class: Arkaan::Permissions::Group do
    factory :group do
      slug 'test_group'
    end
  end
end