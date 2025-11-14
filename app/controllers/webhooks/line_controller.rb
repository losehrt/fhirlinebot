module Webhooks
  class LineController < ApplicationController
    skip_before_action :require_setup_completion
    skip_before_action :verify_authenticity_token

    before_action :cache_raw_body, only: [:create]
    before_action :ensure_event_handlers_loaded

    # POST /webhooks/line
    # Receive and process LINE webhook events
    def create
      # Get the cached raw request body for signature validation
      body = @raw_body

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

    def cache_raw_body
      # Cache the raw request body before Rails parses it
      # This ensures we have the exact bytes that LINE used to create the signature
      @raw_body = request.raw_post
    end

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
        calculated_signature = service.calculate_webhook_signature(body)

        Rails.logger.debug("Signature comparison:")
        Rails.logger.debug("  Received: #{signature[0..20]}...")
        Rails.logger.debug("  Calculated: #{calculated_signature[0..20]}...")
        Rails.logger.debug("  Body length: #{body.bytesize} bytes")

        result = calculated_signature == signature
        Rails.logger.info("Webhook signature validation: #{result ? 'VALID' : 'INVALID'}")

        result
      rescue StandardError => e
        Rails.logger.error("Webhook signature validation error: #{e.class} - #{e.message}")
        false
      end
    end
  end
end
