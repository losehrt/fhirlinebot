require 'rails_helper'

RSpec.describe EchoJob, type: :job do
  let(:user_id) { 'U206d25c2ea6bd87c17655609a1c37cb8' }
  let(:text) { 'Hello Bot' }

  describe '#perform' do
    it 'calls EchoService with the correct parameters' do
      echo_service = instance_double('EchoService')
      allow(EchoService).to receive(:new).and_return(echo_service)
      allow(echo_service).to receive(:echo).and_return(true)

      described_class.perform_now(user_id, text)

      expect(EchoService).to have_received(:new)
      expect(echo_service).to have_received(:echo).with(user_id, text)
    end

    it 'handles errors gracefully' do
      allow(EchoService).to receive(:new).and_raise(StandardError.new('Service error'))

      expect {
        described_class.perform_now(user_id, text)
      }.not_to raise_error
    end

    it 'queues the job' do
      expect {
        described_class.perform_later(user_id, text)
      }.to change(ActiveJob::Base.queue_adapter.enqueued_jobs, :size).by(1)
    end
  end
end
