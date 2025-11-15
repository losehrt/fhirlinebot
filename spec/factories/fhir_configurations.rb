FactoryBot.define do
  factory :fhir_configuration do
    organization
    sequence(:server_url) { |n| "http://localhost:8080/fhir#{n}" }
    description { 'Test FHIR Configuration' }
    is_active { true }
  end
end
