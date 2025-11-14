require 'rails_helper'

RSpec.describe EchoService do
  let(:messaging_service) { instance_double('LineMessagingService') }
  let(:user_id) { 'U206d25c2ea6bd87c17655609a1c37cb8' }

  describe '#echo' do
    context 'with text message' do
      it 'sends back the same text message' do
        text = 'Hello Bot'

        expect(messaging_service).to receive(:send_text_message).with(user_id, text).and_return(true)

        service = EchoService.new(messaging_service)
        result = service.echo(user_id, text)

        expect(result).to be_truthy
      end
    end

    context 'with empty text' do
      it 'still sends the empty text' do
        text = ''

        expect(messaging_service).to receive(:send_text_message).with(user_id, text).and_return(true)

        service = EchoService.new(messaging_service)
        result = service.echo(user_id, text)

        expect(result).to be_truthy
      end
    end

    context 'with special characters' do
      it 'sends back text with special characters preserved' do
        text = '你好世界! @#$%^&*()'

        expect(messaging_service).to receive(:send_text_message).with(user_id, text).and_return(true)

        service = EchoService.new(messaging_service)
        result = service.echo(user_id, text)

        expect(result).to be_truthy
      end
    end

    context 'with very long text' do
      it 'sends back long text' do
        text = 'A' * 5000

        expect(messaging_service).to receive(:send_text_message).with(user_id, text).and_return(true)

        service = EchoService.new(messaging_service)
        result = service.echo(user_id, text)

        expect(result).to be_truthy
      end
    end

    context 'when message service fails' do
      it 'returns false on error' do
        text = 'Hello'

        allow(messaging_service).to receive(:send_text_message).and_raise(StandardError.new('Service error'))

        service = EchoService.new(messaging_service)
        result = service.echo(user_id, text)

        expect(result).to be_falsy
      end
    end

    context 'with nil user_id' do
      it 'returns false' do
        service = EchoService.new(messaging_service)
        result = service.echo(nil, 'Hello')

        expect(result).to be_falsy
      end
    end

    context 'with nil text' do
      it 'sends nil text' do
        text = nil

        expect(messaging_service).to receive(:send_text_message).with(user_id, text).and_return(true)

        service = EchoService.new(messaging_service)
        result = service.echo(user_id, text)

        expect(result).to be_truthy
      end
    end
  end
end
