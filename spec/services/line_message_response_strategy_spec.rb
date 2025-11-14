require 'rails_helper'

RSpec.describe LineMessageResponseStrategy do
  let(:messaging_service) { instance_double(LineMessagingService) }
  let(:user_id) { 'U123' }
  let(:reply_token) { 'reply_token_123' }
  let(:text) { 'Hello World' }

  before do
    allow(messaging_service).to receive(:reply_message).and_return(true)
    allow(messaging_service).to receive(:send_flex_message).and_return(true)
  end

  describe '.for' do
    it 'returns FlexMessageStrategy for :flex mode' do
      strategy = LineMessageResponseStrategy.for(:flex)
      expect(strategy).to be_a(LineMessageResponseStrategy::FlexMessageStrategy)
    end

    it 'returns TextMessageStrategy for :text mode' do
      strategy = LineMessageResponseStrategy.for(:text)
      expect(strategy).to be_a(LineMessageResponseStrategy::TextMessageStrategy)
    end

    it 'raises error for unknown mode' do
      expect {
        LineMessageResponseStrategy.for(:unknown)
      }.to raise_error(ArgumentError, /Unknown response mode/)
    end

    it 'defaults to :flex mode if not specified' do
      strategy = LineMessageResponseStrategy.for(nil)
      expect(strategy).to be_a(LineMessageResponseStrategy::FlexMessageStrategy)
    end
  end

  describe 'response strategies' do
    describe 'FlexMessageStrategy' do
      let(:strategy) { LineMessageResponseStrategy.for(:flex) }

      it 'sends both text reply and flex message' do
        strategy.execute(
          messaging_service: messaging_service,
          user_id: user_id,
          reply_token: reply_token,
          text: text
        )

        expect(messaging_service).to have_received(:reply_message).with(reply_token, text)
        expect(messaging_service).to have_received(:send_flex_message).with(user_id, anything)
      end

      it 'returns true on success' do
        result = strategy.execute(
          messaging_service: messaging_service,
          user_id: user_id,
          reply_token: reply_token,
          text: text
        )

        expect(result).to be_truthy
      end

      it 'handles errors gracefully' do
        allow(messaging_service).to receive(:send_flex_message).and_raise(StandardError, 'API Error')

        result = strategy.execute(
          messaging_service: messaging_service,
          user_id: user_id,
          reply_token: reply_token,
          text: text
        )

        expect(result).to be_falsy
      end
    end

    describe 'TextMessageStrategy' do
      let(:strategy) { LineMessageResponseStrategy.for(:text) }

      it 'sends only text reply' do
        strategy.execute(
          messaging_service: messaging_service,
          user_id: user_id,
          reply_token: reply_token,
          text: text
        )

        expect(messaging_service).to have_received(:reply_message).with(reply_token, text)
        expect(messaging_service).not_to have_received(:send_flex_message)
      end

      it 'returns true on success' do
        result = strategy.execute(
          messaging_service: messaging_service,
          user_id: user_id,
          reply_token: reply_token,
          text: text
        )

        expect(result).to be_truthy
      end
    end
  end
end
