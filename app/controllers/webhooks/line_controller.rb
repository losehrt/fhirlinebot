module Webhooks
  class LineController < ApplicationController
    skip_before_action :require_setup_completion
    skip_before_action :verify_authenticity_token

    # Ensure event handlers are loaded
    require_relative '../../services/line_event_handler'
    require_relative '../../services/line_event_handlers'

    # POST /webhooks/line
    # Receive and process LINE webhook events
    def create
      # Get the raw request body for signature validation
      body = request.raw_post

      # Get the signature from headers
      signature = request.headers['X-Line-Signature']

      # Validate the webhook signature
      unless signature_valid?(body, signature)
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

    def signature_valid?(body, signature)
      return false if signature.blank?

      service = LineMessagingService.new
      service.validate_webhook_signature(body, signature)
    end
  end
end
