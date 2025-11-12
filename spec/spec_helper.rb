# This file is copied to spec/ when you run 'rails generate rspec:install'
require 'rspec/rails'
require 'webmock/rspec'
require 'vcr'
require 'shoulda/matchers'

# Requires supporting ruby files with custom matchers and macros, etc, in
# spec/support/ and its subdirectories. Files matching `spec/**/*_helper.rb` are
# run before `spec_helper.rb` has run.
Dir[Rails.root.join('spec/support/**/*.rb')].each { |f| require f }

begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  puts e.to_s.strip
  exit 1
end

RSpec.configure do |config|
  # Use color in output
  config.color = true

  # Use more verbose output format
  config.formatter = :documentation

  # Run specs in random order to detect order dependencies
  config.order = :random

  # Seed global randomization in this process using the `--seed` CLI option.
  config.seed = srand

  # Use transactional fixtures for faster tests
  config.use_transactional_fixtures = true

  # You can uncomment this line to turn off ActiveRecord support entirely.
  # config.use_active_record = false

  # RSpec Rails can automatically mix in different behaviours to your specs
  # based on their file location, for example enabling you to call `get` and
  # `post` in specs under `spec/requests`.
  # See the helper method `method_missing_to_raise` in the ActionDispatch::TestProcess::ControllerTestUtils
  # configuration below for more information about custom assertions available in controller specs.
  config.infer_spec_type_from_file_location!

  # Filter lines from Rails gems in backtraces.
  config.filter_rails_from_backtrace!

  # arbitrary gems may also be filtered via:
  # config.filter_gems_from_backtrace("gem name")

  # Shoulda Matchers configuration
  Shoulda::Matchers.configure do |shoulda_config|
    shoulda_config.integrate do |with|
      with.test_framework :rspec
      with.library :rails
    end
  end

  # Factory Bot configuration
  config.include FactoryBot::Syntax::Methods

  # Include helpers
  config.include ControllerMacros, type: :controller
  config.include RequestHelpers, type: :request
end

# WebMock configuration
WebMock.disable_net_connect!(allow_localhost: true, allow: ['localhost'])

# VCR configuration
VCR.configure do |config|
  config.cassette_library_dir = 'spec/fixtures/vcr_cassettes'
  config.hook_into :webmock
  config.configure_rspec_metadata!
  config.default_cassette_options = {
    record: :once,
    match_requests_on: [:method, :uri, :body]
  }

  # Filter sensitive data
  config.filter_sensitive_data('<LINE_CHANNEL_ID>') { ENV['LINE_CHANNEL_ID'] }
  config.filter_sensitive_data('<LINE_CHANNEL_SECRET>') { ENV['LINE_CHANNEL_SECRET'] }
  config.filter_sensitive_data('<ACCESS_TOKEN>') { |interaction| interaction.response.headers['Authorization']&.first }
end