# Load LINE event handlers to ensure they're available in production
Rails.application.config.to_prepare do
  load File.expand_path('../../app/services/line_event_handler.rb', __dir__)
  load File.expand_path('../../app/services/line_event_handlers.rb', __dir__)
end
