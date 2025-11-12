FactoryBot.define do
  factory :application_setting do
    line_channel_id { "MyString" }
    line_channel_secret { "MyString" }
    line_channel_secret_encrypted { "MyString" }
    configured { false }
    last_validated_at { "2025-11-12 12:21:14" }
    validation_error { "MyText" }
  end
end
