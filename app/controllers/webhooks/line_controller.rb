module Webhooks
  class LineController < ApplicationController
    skip_before_action :require_setup_completion
    skip_before_action :verify_authenticity_token

    before_action :ensure_event_handlers_loaded

    # POST /webhooks/line
    # Receive and process LINE webhook events
    def create
      # Get the raw request body for signature validation
      body = request.raw_post

      # Get the signature from headers
      signature = request.headers['X-Line-Signature']

      Rails.logger.info("Webhook received: signature=#{signature&.first(10)}..., body_length=#{body.bytesize}")

      # Validate the webhook signature
      unless signature_valid?(body, signature)
        Rails.logger.warn("Webhook signature validation failed for body: #{body[0..100]}")
        render json: { error: 'Invalid signature' }, status: :unauthorized
        return
      end

      # Parse the JSON payload
      payload = JSON.parse(body, symbolize_names: true)

      # Process the webhook events
      service = LineMessagingService.new
      result = service.handle_webhook(payload)

      if result
        render json: { success: true }, status: :ok
      else
        render json: { error: 'Failed to process webhook' }, status: :unprocessable_entity
      end
    rescue JSON::ParserError => e
      Rails.logger.error("Failed to parse webhook payload: #{e.message}")
      render json: { error: 'Invalid JSON' }, status: :bad_request
    end

    # GET /webhooks/line
    # Health check endpoint for LINE webhook
    def index
      render json: { success: true }, status: :ok
    end

    private

    def ensure_event_handlers_loaded
      # Trigger Rails autoloader by referencing the handler classes
      # This ensures they're loaded before webhook processing
      return if @event_handlers_loaded

      [
        MessageHandler,
        FollowEventHandler,
        UnfollowEventHandler,
        PostbackHandler,
        JoinEventHandler,
        LeaveEventHandler,
        MemberJoinedEventHandler,
        MemberLeftEventHandler
      ]
      @event_handlers_loaded = true
    end

    def signature_valid?(body, signature)
      return false if signature.blank?

      begin
        service = LineMessagingService.new
        service.validate_webhook_signature(body, signature)
      rescue StandardError => e
        Rails.logger.error("Webhook signature validation error: #{e.class} - #{e.message}")
        false
      end
    end
  end
end
