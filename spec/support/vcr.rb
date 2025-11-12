require 'vcr'

VCR.configure do |config|
  config.cassette_library_dir = Rails.root.join('spec/fixtures/vcr_cassettes')
  config.hook_into :webmock
  config.configure_rspec_metadata!

  # Record mode options:
  # :new_episodes - Record new interactions, playback old ones
  # :once        - Record once, then always playback
  # :none        - Never record, only playback
  # :all         - Always record, ignore existing cassettes
  config.default_cassette_options = {
    record: :once,
    match_requests_on: [:method, :uri, :body]
  }

  # Filter sensitive information from cassettes
  config.filter_sensitive_data('<LINE_CHANNEL_ID>') { ENV['LINE_CHANNEL_ID'] }
  config.filter_sensitive_data('<LINE_CHANNEL_SECRET>') { ENV['LINE_CHANNEL_SECRET'] }
  config.filter_sensitive_data('<ACCESS_TOKEN>') do |interaction|
    interaction.request.headers['Authorization']&.first&.gsub(/Bearer /, '')
  end
  config.filter_sensitive_data('<USER_ID>') { |interaction| interaction.response.body }
end