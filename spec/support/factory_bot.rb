FactoryBot.define do
  factory :user do
    email { Faker::Internet.email }
    name { Faker::Name.name }
    password { 'SecurePassword123!' }
    password_confirmation { 'SecurePassword123!' }

    trait :with_line_account do
      after(:create) do |user|
        create(:line_account, user: user)
      end
    end

    trait :line_user do
      email { Faker::Internet.email }
      name { Faker::Name.name }
      with_line_account
    end
  end

  factory :line_account do
    user
    line_user_id { SecureRandom.uuid }
    access_token { SecureRandom.hex(32) }
    refresh_token { SecureRandom.hex(32) }
    expires_at { 30.days.from_now }
    display_name { Faker::Name.name }
    picture_url { Faker::Avatar.image }

    trait :expired do
      expires_at { 1.day.ago }
    end

    trait :about_to_expire do
      expires_at { 1.hour.from_now }
    end
  end
end