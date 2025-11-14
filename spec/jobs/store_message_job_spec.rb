require 'rails_helper'

RSpec.describe StoreMessageJob, type: :job do
  let(:line_user_id) { 'U206d25c2ea6bd87c17655609a1c37cb8' }
  let(:message_type) { 'text' }
  let(:content) { 'Hello Bot' }
  let(:line_message_id) { '100001' }
  let(:timestamp) { 1462629479859 }

  describe '#perform' do
    before do
      allow(LineMessage).to receive(:create).and_return(double)
    end

    it 'creates a LineMessage with the correct parameters' do
      described_class.perform_now(line_user_id, message_type, content, line_message_id, timestamp)

      expect(LineMessage).to have_received(:create).with(
        line_user_id: line_user_id,
        message_type: message_type,
        content: content,
        line_message_id: line_message_id,
        timestamp: timestamp
      )
    end

    it 'handles errors gracefully' do
      allow(LineMessage).to receive(:create).and_raise(StandardError.new('DB error'))

      expect {
        described_class.perform_now(line_user_id, message_type, content, line_message_id, timestamp)
      }.not_to raise_error
    end

    it 'queues the job' do
      expect {
        described_class.perform_later(line_user_id, message_type, content, line_message_id, timestamp)
      }.to change(ActiveJob::Base.queue_adapter.enqueued_jobs, :size).by(1)
    end
  end
end
