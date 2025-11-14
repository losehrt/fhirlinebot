# 讓 Zeitwerk 追蹤 LINE handler，避免 superclass mismatch
Rails.application.config.to_prepare do
  ActiveSupport::Dependencies.require_dependency(Rails.root.join('app/services/line_event_handler'))
  ActiveSupport::Dependencies.require_dependency(Rails.root.join('app/services/line_event_handlers'))
end
