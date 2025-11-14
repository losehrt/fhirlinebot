# EchoJob - Asynchronous echo message job
# Queues the echo message to be sent after webhook responds
class EchoJob < ApplicationJob
  queue_as :default

  # Echo a message back to the user
  #
  # @param user_id [String] LINE User ID
  # @param text [String] Text to echo back
  def perform(user_id, text)
    echo_service = EchoService.new
    echo_service.echo(user_id, text)
  rescue StandardError => e
    Rails.logger.error("EchoJob failed for user #{user_id}: #{e.message}")
    # Retry the job
    retry_job wait: 5.seconds, limit: 3
  end
end
