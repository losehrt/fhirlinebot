# LineMessagingService - Handle all LINE Messaging API operations
# Supports sending messages, handling webhooks, and processing various event types
#
# Usage:
#   service = LineMessagingService.new
#   service.send_text_message('U123', 'Hello!')
#   service.handle_webhook(payload)

require 'net/http'
require 'json'
require_relative 'line_event_handler'
require_relative 'line_event_handlers'
require 'openssl'
require 'base64'

class LineMessagingService
  class MessageError < StandardError; end
  class WebhookError < StandardError; end

  API_URL = 'https://api.line.me'
  PUSH_MESSAGE_URL = "#{API_URL}/v2/bot/message/push"
  REPLY_MESSAGE_URL = "#{API_URL}/v2/bot/message/reply"
  PROFILE_URL = "#{API_URL}/v2/bot/profile"

  # Initialize messaging service with channel credentials
  # Priority: explicit params > LineConfig
  #
  # @param channel_id [String, nil] LINE Channel ID
  # @param channel_secret [String, nil] LINE Channel Secret
  def initialize(channel_id: nil, channel_secret: nil)
    @channel_id = channel_id || LineConfig.channel_id
    @channel_secret = channel_secret || LineConfig.channel_secret
    validate_credentials!
  end

  # Send a text message to a user
  #
  # @param user_id [String] LINE User ID
  # @param text [String] Message text
  # @return [Boolean] true if successful
  # @raise [MessageError] if sending fails
  def send_text_message(user_id, text)
    message_body = {
      to: user_id,
      messages: [
        {
          type: 'text',
          text: text
        }
      ]
    }

    push_message(message_body)
  end

  # Send a template message (buttons, confirm, carousel)
  #
  # @param user_id [String] LINE User ID
  # @param template_data [Hash] Template data structure
  # @return [Boolean] true if successful
  def send_template_message(user_id, template_data)
    message_body = {
      to: user_id,
      messages: [
        {
          type: 'template',
          altText: template_data[:title] || 'Template Message',
          template: template_data
        }
      ]
    }

    push_message(message_body)
  end

  # Send a flex message
  #
  # @param user_id [String] LINE User ID
  # @param flex_data [Hash] Flex message container structure
  # @return [Boolean] true if successful
  def send_flex_message(user_id, flex_data)
    message_body = {
      to: user_id,
      messages: [
        {
          type: 'flex',
          altText: 'Flex Message',
          contents: flex_data
        }
      ]
    }

    push_message(message_body)
  end

  # Send a carousel message (multiple templates)
  #
  # @param user_id [String] LINE User ID
  # @param carousel_data [Array<Hash>] Array of template data
  # @return [Boolean] true if successful
  def send_carousel_message(user_id, carousel_data)
    message_body = {
      to: user_id,
      messages: [
        {
          type: 'template',
          altText: 'Carousel Message',
          template: {
            type: 'carousel',
            columns: carousel_data
          }
        }
      ]
    }

    push_message(message_body)
  end

  # Reply to a message using reply token
  #
  # @param reply_token [String] Reply token from webhook
  # @param text [String] Reply message text
  # @return [Boolean] true if successful
  def reply_message(reply_token, text)
    message_body = {
      replyToken: reply_token,
      messages: [
        {
          type: 'text',
          text: text
        }
      ]
    }

    reply_api(message_body)
  end

  # Get user profile information
  #
  # @param user_id [String] LINE User ID
  # @return [Hash] User profile data
  # @raise [MessageError] if request fails
  def get_user_profile(user_id)
    url = "#{PROFILE_URL}/#{user_id}"
    response = make_request(:get, url)

    JSON.parse(response.body, symbolize_names: true)
  end

  # Handle webhook payload from LINE
  # Dispatches to appropriate event handlers
  #
  # @param payload [Hash] Webhook payload
  # @return [Boolean] true if processed successfully
  # @raise [WebhookError] if webhook processing fails
  def handle_webhook(payload)
    events = payload['events'] || payload[:events] || []

    events.each do |event|
      process_event(event)
    end

    true
  rescue StandardError => e
    Rails.logger.error("Webhook error: #{e.message}")
    raise WebhookError, "Failed to process webhook: #{e.message}"
  end

  # Validate webhook signature
  # LINE sends X-Line-Signature header with HMAC SHA256 of body
  #
  # @param body [String] Raw request body
  # @param signature [String] X-Line-Signature header value
  # @return [Boolean] true if signature is valid
  def validate_webhook_signature(body, signature)
    calculated_signature = calculate_signature(body)
    calculated_signature == signature
  end

  private

  # Validate that credentials are properly set
  #
  # @raise [StandardError] if credentials are missing
  def validate_credentials!
    raise 'LINE Channel ID not configured' if @channel_id.blank?
    raise 'LINE Channel Secret not configured' if @channel_secret.blank?
  end

  # Push a message to a user
  #
  # @param message_body [Hash] Message body
  # @return [Boolean] true if successful
  # @raise [MessageError] if push fails
  def push_message(message_body)
    response = make_request(:post, PUSH_MESSAGE_URL, message_body.to_json)

    unless response.code.to_i == 200
      error_data = JSON.parse(response.body)
      raise MessageError, "Failed to send message: #{error_data['message']}"
    end

    true
  end

  # Reply to a message using reply token
  #
  # @param message_body [Hash] Message body with replyToken
  # @return [Boolean] true if successful
  def reply_api(message_body)
    response = make_request(:post, REPLY_MESSAGE_URL, message_body.to_json)

    unless response.code.to_i == 200
      error_data = JSON.parse(response.body)
      raise MessageError, "Failed to send reply: #{error_data['message']}"
    end

    true
  end

  # Make an HTTP request to LINE API
  #
  # @param method [Symbol] HTTP method (:get, :post)
  # @param url [String] Request URL
  # @param body [String] Request body (optional)
  # @return [Net::HTTPResponse] Response object
  def make_request(method, url, body = nil)
    uri = URI(url)

    request = case method
              when :post
                Net::HTTP::Post.new(uri)
              when :get
                Net::HTTP::Get.new(uri)
              else
                raise "Unsupported method: #{method}"
              end

    request['Authorization'] = "Bearer #{@channel_secret}"
    request['Content-Type'] = 'application/json'

    if body
      request.body = body
    end

    Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(request)
    end
  end

  # Process a single event from webhook
  #
  # @param event [Hash] Event data
  def process_event(event)
    event_type = event['type'] || event[:type]

    case event_type
    when 'message'
      handler = MessageHandler.new(event, self)
      handler.call
    when 'follow'
      handler = FollowEventHandler.new(event, self)
      handler.call
    when 'unfollow'
      handler = UnfollowEventHandler.new(event, self)
      handler.call
    when 'postback'
      handler = PostbackHandler.new(event, self)
      handler.call
    when 'join'
      handler = JoinEventHandler.new(event, self)
      handler.call
    when 'leave'
      handler = LeaveEventHandler.new(event, self)
      handler.call
    when 'memberJoined'
      handler = MemberJoinedEventHandler.new(event, self)
      handler.call
    when 'memberLeft'
      handler = MemberLeftEventHandler.new(event, self)
      handler.call
    else
      Rails.logger.debug("Unsupported event type: #{event_type}")
    end
  end

  # Calculate HMAC SHA256 signature
  #
  # @param body [String] Request body
  # @return [String] Base64-encoded signature
  def calculate_signature(body)
    hash = OpenSSL::HMAC.digest(OpenSSL::Digest.new('sha256'), @channel_secret, body)
    Base64.strict_encode64(hash)
  end
end
