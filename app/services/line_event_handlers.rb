# LineEventHandlers - Namespace for all event handler classes
# This module serves as a container for Zeitwerk autoloading
module LineEventHandlers
end

# Message event handler for TEXT, IMAGE, LOCATION, etc.
class MessageHandler < LineEventHandler
  def call
    message = @event['message'] || @event[:message]
    return false unless message

    message_type = message['type'] || message[:type]

    case message_type
    when 'text'
      handle_text_message(message)
    when 'image'
      handle_image_message(message)
    when 'video'
      handle_video_message(message)
    when 'audio'
      handle_audio_message(message)
    when 'file'
      handle_file_message(message)
    when 'location'
      handle_location_message(message)
    when 'sticker'
      handle_sticker_message(message)
    else
      Rails.logger.debug("Unsupported message type: #{message_type}")
      true
    end
  rescue StandardError => e
    Rails.logger.error("Error handling message: #{e.message}")
    false
  end

  private

  def handle_text_message(message)
    text = message['text'] || message[:text]
    log_event(:info, "Text message: '#{text}'")

    # Store message in database asynchronously
    StoreMessageJob.perform_later(
      @user_id,
      'text',
      text,
      message['id'] || message[:id],
      @timestamp
    )

    # Reply with echo message immediately
    send_reply(text)

    # Also send a flex message for rich formatting
    send_flex_reply(text)

    true
  end

  # Send a flex message to the user
  #
  # @param text [String] The text to display in flex message
  # @return [Boolean] true if successful
  def send_flex_reply(text)
    return false unless @user_id

    flex_message = LineFlexMessageBuilder.build_text_reply(text)
    result = @messaging_service.send_flex_message(@user_id, flex_message)
    Rails.logger.info("[LINE Webhook] Flex message sent to #{@user_id}: #{result}")
    result
  rescue StandardError => e
    Rails.logger.error("[LINE Webhook] Failed to send flex message: #{e.class} - #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))
    false
  end

  def handle_image_message(message)
    log_event(:info, 'Image message received')

    LineMessage.create(
      line_user_id: @user_id,
      message_type: 'image',
      line_message_id: message['id'] || message[:id],
      timestamp: @timestamp
    )

    true
  end

  def handle_video_message(message)
    log_event(:info, 'Video message received')

    LineMessage.create(
      line_user_id: @user_id,
      message_type: 'video',
      line_message_id: message['id'] || message[:id],
      timestamp: @timestamp
    )

    true
  end

  def handle_audio_message(message)
    log_event(:info, 'Audio message received')

    LineMessage.create(
      line_user_id: @user_id,
      message_type: 'audio',
      line_message_id: message['id'] || message[:id],
      timestamp: @timestamp
    )

    true
  end

  def handle_file_message(message)
    log_event(:info, 'File message received')

    LineMessage.create(
      line_user_id: @user_id,
      message_type: 'file',
      line_message_id: message['id'] || message[:id],
      timestamp: @timestamp
    )

    true
  end

  def handle_location_message(message)
    log_event(:info, 'Location message received')

    LineMessage.create(
      line_user_id: @user_id,
      message_type: 'location',
      content: {
        latitude: message['latitude'] || message[:latitude],
        longitude: message['longitude'] || message[:longitude],
        address: message['address'] || message[:address]
      }.to_json,
      line_message_id: message['id'] || message[:id],
      timestamp: @timestamp
    )

    true
  end

  def handle_sticker_message(message)
    log_event(:info, 'Sticker message received')

    LineMessage.create(
      line_user_id: @user_id,
      message_type: 'sticker',
      content: {
        packageId: message['packageId'] || message[:packageId],
        stickerId: message['stickerId'] || message[:stickerId]
      }.to_json,
      line_message_id: message['id'] || message[:id],
      timestamp: @timestamp
    )

    true
  end
end

# Follow event handler
class FollowEventHandler < LineEventHandler
  def call
    log_event(:info, 'User followed the bot')

    # Create or update user
    User.find_or_create_by(line_user_id: @user_id)

    # Send welcome message
    send_reply('Thanks for following! We look forward to serving you.')

    true
  rescue StandardError => e
    Rails.logger.error("Error handling follow event: #{e.message}")
    false
  end
end

# Unfollow event handler
class UnfollowEventHandler < LineEventHandler
  def call
    log_event(:info, 'User unfollowed the bot')

    # Mark user as unfollowed
    user = User.find_by(line_user_id: @user_id)
    user.update(line_account: nil) if user

    true
  rescue StandardError => e
    Rails.logger.error("Error handling unfollow event: #{e.message}")
    false
  end
end

# Postback event handler
class PostbackHandler < LineEventHandler
  def call
    postback = @event['postback'] || @event[:postback]
    return false unless postback

    data = postback['data'] || postback[:data]
    log_event(:info, "Postback event: #{data}")

    # Parse postback data
    params = parse_postback_data(data)

    # Store postback event
    LinePostback.create(
      line_user_id: @user_id,
      data: data,
      params: params.to_json,
      timestamp: @timestamp
    )

    true
  rescue StandardError => e
    Rails.logger.error("Error handling postback event: #{e.message}")
    false
  end

  private

  def parse_postback_data(data)
    data.split('&').each_with_object({}) do |pair, hash|
      key, value = pair.split('=')
      hash[key] = CGI.unescape(value) if key && value
    end
  end
end

# Join event handler (bot joined a group/room)
class JoinEventHandler < LineEventHandler
  def call
    source = @event['source'] || @event[:source]
    source_type = source['type'] || source[:type]

    case source_type
    when 'group'
      group_id = source['groupId'] || source[:groupId]
      log_event(:info, "Bot joined group: #{group_id}")
    when 'room'
      room_id = source['roomId'] || source[:roomId]
      log_event(:info, "Bot joined room: #{room_id}")
    end

    true
  end
end

# Leave event handler (bot left a group/room)
class LeaveEventHandler < LineEventHandler
  def call
    source = @event['source'] || @event[:source]
    source_type = source['type'] || source[:type]

    case source_type
    when 'group'
      group_id = source['groupId'] || source[:groupId]
      log_event(:info, "Bot left group: #{group_id}")
    when 'room'
      room_id = source['roomId'] || source[:roomId]
      log_event(:info, "Bot left room: #{room_id}")
    end

    true
  end
end

# Member joined event handler
class MemberJoinedEventHandler < LineEventHandler
  def call
    log_event(:info, 'Member joined')
    true
  end
end

# Member left event handler
class MemberLeftEventHandler < LineEventHandler
  def call
    log_event(:info, 'Member left')
    true
  end
end
