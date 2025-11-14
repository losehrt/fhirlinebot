require 'rails_helper'

RSpec.describe 'LINE Webhook', type: :request do
  before do
    unless @credentials_mocked
      allow(Rails.application).to receive(:credentials).and_wrap_original do |method, *args|
        double(dig: nil, present?: false)
      end
      @credentials_mocked = true
    end
  end

  let(:channel_id) { '2008492815' }
  let(:channel_secret) { 'f6909227204f50c8f43e78f9393315ae' }
  let(:webhook_path) { '/webhooks/line' }

  describe 'POST /webhooks/line' do
    let(:payload) do
      {
        events: [
          {
            type: 'message',
            message: {
              type: 'text',
              id: '100001',
              text: 'Hello Bot'
            },
            timestamp: 1462629479859,
            replyToken: 'nHuyWiB7yP5Zw52FIkcQT',
            source: {
              type: 'user',
              userId: 'U206d25c2ea6bd87c17655609a1c37cb8'
            }
          }
        ]
      }
    end

    let(:body) { payload.to_json }
    let(:signature) do
      hash = OpenSSL::HMAC.digest(OpenSSL::Digest.new('sha256'), channel_secret, body)
      Base64.strict_encode64(hash)
    end

    context 'with valid webhook signature' do
      it 'accepts and processes webhook' do
        allow(LineMessagingService).to receive(:new).and_return(
          instance_double('LineMessagingService',
                         handle_webhook: true,
                         validate_webhook_signature: true)
        )

        post webhook_path,
             params: body,
             headers: {
               'Content-Type' => 'application/json',
               'X-Line-Signature' => signature
             }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include('success')
      end
    end

    context 'with invalid webhook signature' do
      it 'rejects webhook' do
        allow(LineMessagingService).to receive(:new).and_return(
          instance_double('LineMessagingService',
                         validate_webhook_signature: false)
        )

        post webhook_path,
             params: payload,
             headers: {
               'Content-Type' => 'application/json',
               'X-Line-Signature' => 'invalid_signature'
             }

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'with missing signature' do
      it 'rejects webhook' do
        post webhook_path,
             params: payload,
             headers: { 'Content-Type' => 'application/json' }

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'with multiple events' do
      let(:payload) do
        {
          events: [
            {
              type: 'message',
              message: {
                type: 'text',
                id: '100001',
                text: 'Hello'
              },
              timestamp: 1462629479859,
              replyToken: 'nHuyWiB7yP5Zw52FIkcQT',
              source: {
                type: 'user',
                userId: 'U206d25c2ea6bd87c17655609a1c37cb8'
              }
            },
            {
              type: 'follow',
              timestamp: 1462629479859,
              replyToken: 'nHuyWiB7yP5Zw52FIkcQT',
              source: {
                type: 'user',
                userId: 'U206d25c2ea6bd87c17655609a1c37cb8'
              }
            }
          ]
        }
      end

      let(:body_multi) { payload.to_json }
      let(:signature_multi) do
        hash = OpenSSL::HMAC.digest(OpenSSL::Digest.new('sha256'), channel_secret, body_multi)
        Base64.strict_encode64(hash)
      end

      it 'processes all events' do
        allow(LineMessagingService).to receive(:new).and_return(
          instance_double('LineMessagingService',
                         handle_webhook: true,
                         validate_webhook_signature: true)
        )

        post webhook_path,
             params: body_multi,
             headers: {
               'Content-Type' => 'application/json',
               'X-Line-Signature' => signature_multi
             }

        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe 'GET /webhooks/line' do
    it 'returns 200 OK for health check' do
      get webhook_path

      expect(response).to have_http_status(:ok)
    end
  end
end
