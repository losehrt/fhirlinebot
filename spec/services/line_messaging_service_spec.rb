require 'rails_helper'

# Load event handlers
require_relative '../../app/services/line_event_handler'
require_relative '../../app/services/line_event_handlers'

RSpec.describe LineMessagingService do
  # Mock credentials globally
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
  let(:access_token) { 'test_access_token_1234567890' }
  let(:service) { LineMessagingService.new(channel_id:, channel_secret:, access_token:) }

  describe 'initialization' do
    it 'initializes with channel_id, channel_secret, and access_token' do
      expect(service.instance_variable_get(:@channel_id)).to eq(channel_id)
      expect(service.instance_variable_get(:@channel_secret)).to eq(channel_secret)
      expect(service.instance_variable_get(:@access_token)).to eq(access_token)
    end

    it 'uses LineConfig when no credentials provided' do
      allow(LineConfig).to receive(:messaging_channel_id).and_return(channel_id)
      allow(LineConfig).to receive(:messaging_channel_secret).and_return(channel_secret)
      allow(LineConfig).to receive(:access_token).and_return(access_token)

      service = LineMessagingService.new
      expect(service.instance_variable_get(:@channel_id)).to eq(channel_id)
      expect(service.instance_variable_get(:@channel_secret)).to eq(channel_secret)
      expect(service.instance_variable_get(:@access_token)).to eq(access_token)
    end
  end

  describe '#send_text_message' do
    it 'sends a text message to a user' do
      user_id = 'U12345'
      text = 'Hello, World!'

      stub_request(:post, 'https://api.line.me/v2/bot/message/push')
        .with(
          headers: {
            'Authorization' => "Bearer #{access_token}",
            'Content-Type' => 'application/json'
          }
        )
        .to_return(status: 200, body: '{}')

      result = service.send_text_message(user_id, text)

      expect(result).to be_truthy
      expect(WebMock).to have_requested(:post, 'https://api.line.me/v2/bot/message/push')
    end

    it 'raises error on failed text message' do
      user_id = 'U12345'
      text = 'Hello, World!'

      stub_request(:post, 'https://api.line.me/v2/bot/message/push')
        .to_return(status: 400, body: '{"message": "Invalid request"}')

      expect {
        service.send_text_message(user_id, text)
      }.to raise_error(LineMessagingService::MessageError)
    end
  end

  describe '#send_template_message' do
    it 'sends a button template message' do
      user_id = 'U12345'
      template_data = {
        type: 'buttons',
        title: 'Choose an action',
        text: 'What would you like to do?',
        actions: [
          { type: 'message', label: 'Yes', text: 'Yes' },
          { type: 'message', label: 'No', text: 'No' }
        ]
      }

      stub_request(:post, 'https://api.line.me/v2/bot/message/push')
        .to_return(status: 200, body: '{}')

      result = service.send_template_message(user_id, template_data)

      expect(result).to be_truthy
    end
  end

  describe '#send_flex_message' do
    it 'sends a flex message' do
      user_id = 'U12345'
      flex_data = {
        type: 'box',
        layout: 'vertical',
        contents: [
          { type: 'text', text: 'Hello Flex' }
        ]
      }

      stub_request(:post, 'https://api.line.me/v2/bot/message/push')
        .to_return(status: 200, body: '{}')

      result = service.send_flex_message(user_id, flex_data)

      expect(result).to be_truthy
    end
  end

  describe '#send_carousel_message' do
    it 'sends a carousel of templates' do
      user_id = 'U12345'
      carousel_data = [
        {
          type: 'buttons',
          title: 'Item 1',
          text: 'Description 1',
          actions: [{ type: 'message', label: 'Select', text: 'Item 1' }]
        },
        {
          type: 'buttons',
          title: 'Item 2',
          text: 'Description 2',
          actions: [{ type: 'message', label: 'Select', text: 'Item 2' }]
        }
      ]

      stub_request(:post, 'https://api.line.me/v2/bot/message/push')
        .to_return(status: 200, body: '{}')

      result = service.send_carousel_message(user_id, carousel_data)

      expect(result).to be_truthy
    end
  end

  describe '#handle_webhook' do
    it 'processes a text message event' do
      payload = {
        events: [
          {
            type: 'message',
            message: {
              type: 'text',
              id: '100001',
              text: 'Hello'
            },
            timestamp: 1462629479859,
            mode: 'active',
            replyToken: 'nHuyWiB7yP5Zw52FIkcQT',
            source: {
              type: 'user',
              userId: 'U206d25c2ea6bd87c17655609a1c37cb8'
            }
          }
        ]
      }

      message_handler = instance_double('MessageHandler')
      allow(message_handler).to receive(:call).and_return(true)
      allow(MessageHandler).to receive(:new).and_return(message_handler)

      result = service.handle_webhook(payload)

      expect(result).to eq(true)
    end

    it 'processes a follow event' do
      payload = {
        events: [
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

      follow_handler = instance_double('FollowEventHandler')
      allow(follow_handler).to receive(:call).and_return(true)
      allow(FollowEventHandler).to receive(:new).and_return(follow_handler)

      result = service.handle_webhook(payload)

      expect(result).to eq(true)
    end

    it 'processes a postback event' do
      payload = {
        events: [
          {
            type: 'postback',
            postback: {
              data: 'action=buy&itemid=123'
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

      postback_handler = instance_double('PostbackHandler')
      allow(postback_handler).to receive(:call).and_return(true)
      allow(PostbackHandler).to receive(:new).and_return(postback_handler)

      result = service.handle_webhook(payload)

      expect(result).to eq(true)
    end

    it 'ignores unsupported event types' do
      payload = {
        events: [
          {
            type: 'unsupported_type',
            timestamp: 1462629479859
          }
        ]
      }

      result = service.handle_webhook(payload)

      expect(result).to eq(true)
    end
  end

  describe '#validate_webhook_signature' do
    it 'validates correct webhook signature' do
      body = '{"events":[]}'
      # Calculate the actual signature using the same method
      hash = OpenSSL::HMAC.digest(OpenSSL::Digest.new('sha256'), channel_secret, body)
      signature = Base64.strict_encode64(hash)

      result = service.validate_webhook_signature(body, signature)

      expect(result).to be_truthy
    end

    it 'rejects invalid webhook signature' do
      body = '{"events":[]}'
      signature = 'invalid_signature'

      result = service.validate_webhook_signature(body, signature)

      expect(result).to be_falsy
    end
  end

  describe '#reply_message' do
    it 'sends a reply message' do
      reply_token = 'nHuyWiB7yP5Zw52FIkcQT'
      text = 'Thanks for your message'

      stub_request(:post, 'https://api.line.me/v2/bot/message/reply')
        .to_return(status: 200, body: '{}')

      result = service.reply_message(reply_token, text)

      expect(result).to be_truthy
    end
  end

  describe '#get_user_profile' do
    it 'fetches user profile information' do
      user_id = 'U206d25c2ea6bd87c17655609a1c37cb8'

      stub_request(:get, "https://api.line.me/v2/bot/profile/#{user_id}")
        .to_return(
          status: 200,
          body: {
            userId: user_id,
            displayName: 'John Doe',
            pictureUrl: 'https://example.com/pic.jpg',
            statusMessage: 'Hello!'
          }.to_json
        )

      result = service.get_user_profile(user_id)

      expect(result[:userId]).to eq(user_id)
      expect(result[:displayName]).to eq('John Doe')
    end
  end
end
