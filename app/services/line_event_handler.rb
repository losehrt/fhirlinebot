# LineEventHandler - Base class for LINE webhook event handlers
# All event handlers inherit from this class

class LineEventHandler
  # Initialize handler with event data and messaging service
  #
  # @param event [Hash] LINE webhook event
  # @param messaging_service [LineMessagingService] Service instance
  def initialize(event, messaging_service = nil)
    @event = event
    @messaging_service = messaging_service || LineMessagingService.new
    @user_id = extract_user_id
    @reply_token = event['replyToken'] || event[:replyToken]
    @timestamp = event['timestamp'] || event[:timestamp]
  end

  # Process the event - override in subclasses
  #
  # @return [Boolean] true if handled successfully
  def call
    raise NotImplementedError, "#{self.class} must implement #call"
  end

  protected

  # Extract user ID from various event types
  #
  # @return [String] LINE User ID
  def extract_user_id
    source = @event['source'] || @event[:source]
    return unless source

    source['userId'] || source[:userId]
  end

  # Send a reply message to the user
  #
  # @param text [String] Reply message text
  # @return [Boolean] true if successful
  def send_reply(text)
    return false unless @reply_token

    @messaging_service.reply_message(@reply_token, text)
  rescue StandardError => e
    Rails.logger.error("[LINE Webhook] Failed to send reply: #{e.class} - #{e.message}")
    false
  end

  # Send a push message to the user
  #
  # @param text [String] Message text
  # @return [Boolean] true if successful
  def send_message(text)
    return false unless @user_id

    @messaging_service.send_text_message(@user_id, text)
  end

  # Get user profile information
  #
  # @return [Hash] User profile data
  def get_user_profile
    return nil unless @user_id

    @messaging_service.get_user_profile(@user_id)
  end

  # Log event information
  #
  # @param level [Symbol] Log level (:info, :debug, :warn, :error)
  # @param message [String] Message to log
  def log_event(level = :info, message = nil)
    log_message = message || "#{self.class.name} event from user #{@user_id}"
    Rails.logger.send(level, "[LINE Webhook] #{log_message}")
  end
end
