# Ensure LINE event handler classes are loaded before webhook processing
# This prevents "superclass mismatch" errors in concurrent requests
Rails.application.config.to_prepare do
  # Remove old class definitions to prevent superclass mismatch
  # when code is reloaded in development
  [
    :MessageHandler, :FollowEventHandler, :UnfollowEventHandler,
    :PostbackHandler, :JoinEventHandler, :LeaveEventHandler,
    :MemberJoinedEventHandler, :MemberLeftEventHandler, :LineEventHandler
  ].each do |const|
    Object.send(:remove_const, const) if Object.const_defined?(const)
  end

  # Load base class first
  require_dependency 'line_event_handler'
  # Then load all handler implementations
  require_dependency 'line_event_handlers'
end
