FactoryBot.define do
  factory :ride do
    start_address { "123 Main St" }
    destination_address { "456 Oak Ave" }
    driver
    score { rand(1..100) }
  end
end
