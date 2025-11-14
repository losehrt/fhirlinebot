FactoryBot.define do
  factory :line_message do
    line_user_id { "MyString" }
    message_type { "MyString" }
    content { "MyText" }
    line_message_id { "MyString" }
    timestamp { 1 }
  end
end
