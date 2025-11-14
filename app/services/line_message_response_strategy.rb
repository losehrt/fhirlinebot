# LineMessageResponseStrategy - Strategy pattern for different message response modes
# Allows switching between text, flex message, quick reply, etc.
#
# Usage:
#   strategy = LineMessageResponseStrategy.for(:flex)
#   strategy.execute(messaging_service: service, user_id: 'U123', reply_token: 'token', text: 'Hello')

class LineMessageResponseStrategy
  # Factory method to get strategy for a given mode
  #
  # @param mode [Symbol, String, nil] Response mode (:flex, :text, etc.)
  # @return [LineMessageResponseStrategy] Strategy instance
  # @raise [ArgumentError] if mode is unknown
  def self.for(mode)
    mode = mode&.to_sym || :flex

    case mode
    when :flex
      FlexMessageStrategy.new
    when :text
      TextMessageStrategy.new
    else
      raise ArgumentError, "Unknown response mode: #{mode}"
    end
  end

  # Base strategy class with common interface
  class BaseStrategy
    # Execute the response strategy
    #
    # @param messaging_service [LineMessagingService] Service to send messages
    # @param user_id [String] LINE user ID
    # @param reply_token [String] Reply token from webhook
    # @param text [String] User's message text
    # @return [Boolean] true if successful
    def execute(messaging_service:, user_id:, reply_token:, text:)
      raise NotImplementedError, "#{self.class} must implement execute"
    end

    protected

    # Send a text reply using reply token
    #
    # @param messaging_service [LineMessagingService] Service to send messages
    # @param reply_token [String] Reply token
    # @param text [String] Message text
    # @return [Boolean] true if successful
    def send_text_reply(messaging_service, reply_token, text)
      messaging_service.reply_message(reply_token, text)
    rescue StandardError => e
      Rails.logger.error("[LineMessageResponseStrategy] Failed to send text reply: #{e.class} - #{e.message}")
      false
    end

    # Send a flex message using push API
    #
    # @param messaging_service [LineMessagingService] Service to send messages
    # @param user_id [String] LINE user ID
    # @param text [String] Message text to display
    # @return [Boolean] true if successful
    def send_flex_message_reply(messaging_service, user_id, text)
      flex_message = LineFlexMessageBuilder.build_text_reply(text)
      messaging_service.send_flex_message(user_id, flex_message)
    rescue StandardError => e
      Rails.logger.error("[LineMessageResponseStrategy] Failed to send flex message: #{e.class} - #{e.message}")
      false
    end
  end

  # Flex message response strategy - sends both text and styled flex message
  class FlexMessageStrategy < BaseStrategy
    def execute(messaging_service:, user_id:, reply_token:, text:)
      # Send text reply
      text_result = send_text_reply(messaging_service, reply_token, text)

      # Send flex message
      flex_result = send_flex_message_reply(messaging_service, user_id, text)

      text_result && flex_result
    end
  end

  # Text-only response strategy - sends only text reply
  class TextMessageStrategy < BaseStrategy
    def execute(messaging_service:, user_id:, reply_token:, text:)
      send_text_reply(messaging_service, reply_token, text)
    end
  end
end
