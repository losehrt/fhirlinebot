require 'rails_helper'
require_relative '../../app/services/line_event_handler'
require_relative '../../app/services/line_event_handlers'

RSpec.describe 'LINE Event Handlers' do
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
  let(:messaging_service) { LineMessagingService.new(channel_id:, channel_secret:) }
  let(:user_id) { 'U206d25c2ea6bd87c17655609a1c37cb8' }

  describe MessageHandler do
    before do
      # Mock LineMessage creation
      allow(LineMessage).to receive(:create).and_return(double)
    end

    describe 'text message' do
      it 'handles text message and stores it' do
        event = {
          'type' => 'message',
          'message' => {
            'type' => 'text',
            'id' => '100001',
            'text' => 'Hello Bot'
          },
          'timestamp' => 1462629479859,
          'replyToken' => 'nHuyWiB7yP5Zw52FIkcQT',
          'source' => {
            'type' => 'user',
            'userId' => user_id
          }
        }

        handler = MessageHandler.new(event, messaging_service)
        result = handler.call

        expect(result).to be_truthy
        expect(LineMessage).to have_received(:create)
      end
    end

    describe 'image message' do
      it 'handles image message' do
        event = {
          'type' => 'message',
          'message' => {
            'type' => 'image',
            'id' => '100001'
          },
          'timestamp' => 1462629479859,
          'replyToken' => 'nHuyWiB7yP5Zw52FIkcQT',
          'source' => {
            'type' => 'user',
            'userId' => user_id
          }
        }

        handler = MessageHandler.new(event, messaging_service)
        result = handler.call

        expect(result).to be_truthy
      end
    end

    describe 'location message' do
      it 'handles location message' do
        event = {
          'type' => 'message',
          'message' => {
            'type' => 'location',
            'id' => '100001',
            'latitude' => 35.6735,
            'longitude' => 139.5703,
            'address' => 'Tokyo, Japan'
          },
          'timestamp' => 1462629479859,
          'replyToken' => 'nHuyWiB7yP5Zw52FIkcQT',
          'source' => {
            'type' => 'user',
            'userId' => user_id
          }
        }

        handler = MessageHandler.new(event, messaging_service)
        result = handler.call

        expect(result).to be_truthy
      end
    end

    describe 'sticker message' do
      it 'handles sticker message' do
        event = {
          'type' => 'message',
          'message' => {
            'type' => 'sticker',
            'id' => '100001',
            'packageId' => '1',
            'stickerId' => '1'
          },
          'timestamp' => 1462629479859,
          'replyToken' => 'nHuyWiB7yP5Zw52FIkcQT',
          'source' => {
            'type' => 'user',
            'userId' => user_id
          }
        }

        handler = MessageHandler.new(event, messaging_service)
        result = handler.call

        expect(result).to be_truthy
      end
    end
  end

  describe FollowEventHandler do
    it 'handles follow event' do
      event = {
        'type' => 'follow',
        'timestamp' => 1462629479859,
        'replyToken' => 'nHuyWiB7yP5Zw52FIkcQT',
        'source' => {
          'type' => 'user',
          'userId' => user_id
        }
      }

      stub_request(:post, 'https://api.line.me/v2/bot/message/reply')
        .to_return(status: 200, body: '{}')

      # Mock User operations
      allow(User).to receive(:find_or_create_by).and_return(double)

      handler = FollowEventHandler.new(event, messaging_service)
      result = handler.call

      expect(result).to be_truthy
    end
  end

  describe UnfollowEventHandler do
    it 'handles unfollow event' do
      event = {
        'type' => 'unfollow',
        'timestamp' => 1462629479859,
        'source' => {
          'type' => 'user',
          'userId' => user_id
        }
      }

      # Mock User operations
      user = double(update: true)
      allow(User).to receive(:find_by).and_return(user)

      handler = UnfollowEventHandler.new(event, messaging_service)
      result = handler.call

      expect(result).to be_truthy
    end
  end

  describe PostbackHandler do
    it 'handles postback event with parsed data' do
      event = {
        'type' => 'postback',
        'postback' => {
          'data' => 'action=buy&itemid=123&qty=2'
        },
        'timestamp' => 1462629479859,
        'replyToken' => 'nHuyWiB7yP5Zw52FIkcQT',
        'source' => {
          'type' => 'user',
          'userId' => user_id
        }
      }

      # Mock LinePostback creation
      allow(LinePostback).to receive(:create).and_return(double)

      handler = PostbackHandler.new(event, messaging_service)
      result = handler.call

      expect(result).to be_truthy
      expect(LinePostback).to have_received(:create)
    end
  end

  describe JoinEventHandler do
    it 'handles join event for group' do
      event = {
        'type' => 'join',
        'timestamp' => 1462629479859,
        'replyToken' => 'nHuyWiB7yP5Zw52FIkcQT',
        'source' => {
          'type' => 'group',
          'groupId' => 'Ca56f360b0d3f1fab8bf5f50c8f7a0e81'
        }
      }

      handler = JoinEventHandler.new(event, messaging_service)
      result = handler.call

      expect(result).to be_truthy
    end

    it 'handles join event for room' do
      event = {
        'type' => 'join',
        'timestamp' => 1462629479859,
        'replyToken' => 'nHuyWiB7yP5Zw52FIkcQT',
        'source' => {
          'type' => 'room',
          'roomId' => 'Ra56f360b0d3f1fab8bf5f50c8f7a0e81'
        }
      }

      handler = JoinEventHandler.new(event, messaging_service)
      result = handler.call

      expect(result).to be_truthy
    end
  end

  describe LeaveEventHandler do
    it 'handles leave event for group' do
      event = {
        'type' => 'leave',
        'timestamp' => 1462629479859,
        'source' => {
          'type' => 'group',
          'groupId' => 'Ca56f360b0d3f1fab8bf5f50c8f7a0e81'
        }
      }

      handler = LeaveEventHandler.new(event, messaging_service)
      result = handler.call

      expect(result).to be_truthy
    end

    it 'handles leave event for room' do
      event = {
        'type' => 'leave',
        'timestamp' => 1462629479859,
        'source' => {
          'type' => 'room',
          'roomId' => 'Ra56f360b0d3f1fab8bf5f50c8f7a0e81'
        }
      }

      handler = LeaveEventHandler.new(event, messaging_service)
      result = handler.call

      expect(result).to be_truthy
    end
  end

  describe MemberJoinedEventHandler do
    it 'handles member joined event' do
      event = {
        'type' => 'memberJoined',
        'timestamp' => 1462629479859,
        'replyToken' => 'nHuyWiB7yP5Zw52FIkcQT',
        'source' => {
          'type' => 'group',
          'groupId' => 'Ca56f360b0d3f1fab8bf5f50c8f7a0e81'
        }
      }

      handler = MemberJoinedEventHandler.new(event, messaging_service)
      result = handler.call

      expect(result).to be_truthy
    end
  end

  describe MemberLeftEventHandler do
    it 'handles member left event' do
      event = {
        'type' => 'memberLeft',
        'timestamp' => 1462629479859,
        'replyToken' => 'nHuyWiB7yP5Zw52FIkcQT',
        'source' => {
          'type' => 'group',
          'groupId' => 'Ca56f360b0d3f1fab8bf5f50c8f7a0e81'
        }
      }

      handler = MemberLeftEventHandler.new(event, messaging_service)
      result = handler.call

      expect(result).to be_truthy
    end
  end

  describe LineEventHandler do
    describe '#extract_user_id' do
      it 'extracts user ID from event source' do
        event = {
          'source' => {
            'type' => 'user',
            'userId' => user_id
          }
        }

        handler = LineEventHandler.new(event, messaging_service)
        # Access private method for testing
        extracted_id = handler.instance_variable_get(:@user_id)

        expect(extracted_id).to eq(user_id)
      end
    end

    describe '#log_event' do
      it 'logs event information' do
        event = {
          'source' => {
            'type' => 'user',
            'userId' => user_id
          }
        }

        handler = LineEventHandler.new(event, messaging_service)

        expect(Rails.logger).to receive(:info).with(/LineEventHandler event from user/)
        handler.send(:log_event, :info)
      end
    end
  end
end
