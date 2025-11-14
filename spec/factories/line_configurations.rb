FactoryBot.define do
  factory :line_configuration do
    organization { nil }
    sequence(:name) { |n| "Channel #{n}" }
    sequence(:channel_id) { |n| "CHANNEL_#{n}" }
    sequence(:channel_secret) { |n| "SECRET_#{n}" }
    sequence(:redirect_uri) { |n| "https://example.com/callback#{n}" }
    is_default { false }
    is_active { true }
    last_used_at { nil }
    description { "Test configuration" }
  end
end
