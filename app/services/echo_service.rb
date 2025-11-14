# EchoService - Echo message back to user
# Simple service that receives a message and sends it back
class EchoService
  def initialize(messaging_service = nil)
    @messaging_service = messaging_service || LineMessagingService.new
  end

  # Echo a text message back to the user
  #
  # @param user_id [String] LINE User ID
  # @param text [String] Text to echo back
  # @return [Boolean] true if successful, false otherwise
  def echo(user_id, text)
    return false if user_id.blank?

    @messaging_service.send_text_message(user_id, text)
  rescue StandardError => e
    Rails.logger.error("Echo service error: #{e.message}")
    false
  end
end
