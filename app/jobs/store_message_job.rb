# StoreMessageJob - Asynchronously store messages in database
# Queues the message storage to not block webhook response
class StoreMessageJob < ApplicationJob
  queue_as :default

  # Store a line message
  #
  # @param line_user_id [String] LINE User ID
  # @param message_type [String] Type of message (text, image, etc)
  # @param content [String] Message content
  # @param line_message_id [String] LINE message ID
  # @param timestamp [Integer] Message timestamp
  def perform(line_user_id, message_type, content, line_message_id, timestamp)
    LineMessage.create(
      line_user_id: line_user_id,
      message_type: message_type,
      content: content,
      line_message_id: line_message_id,
      timestamp: timestamp
    )
  rescue StandardError => e
    Rails.logger.error("StoreMessageJob failed for user #{line_user_id}: #{e.message}")
    # Retry the job
    retry_job wait: 5.seconds, limit: 3
  end
end
