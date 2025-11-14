# LineFlexMessageBuilder - Build LINE Flex Messages for rich text responses
# Reference: https://developers.line.biz/en/docs/messaging-api/using-flex-messages/
#
# Usage:
#   flex_message = LineFlexMessageBuilder.build_text_reply("User's message")
#   service.send_flex_message(user_id, flex_message)

class LineFlexMessageBuilder
  # Build a flex message to display user text with rich formatting
  #
  # @param user_text [String] The text to display
  # @return [Hash] Flex message container structure
  def self.build_text_reply(user_text)
    {
      type: 'box',
      layout: 'vertical',
      contents: build_text_contents(user_text),
      spacing: 'md',
      margin: 'md'
    }
  end

  private

  # Build the contents array for the flex message
  #
  # @param user_text [String] The text to display
  # @return [Array<Hash>] Array of content elements
  def self.build_text_contents(user_text)
    contents = []

    # Add header
    contents << {
      type: 'box',
      layout: 'vertical',
      contents: [
        {
          type: 'text',
          text: 'User Message',
          weight: 'bold',
          size: 'md',
          color: '#1DB446'
        }
      ],
      paddingBottom: 'md'
    }

    # Add separator
    contents << {
      type: 'separator',
      margin: 'md'
    }

    # Add user text with wrapping and proper formatting
    contents << {
      type: 'box',
      layout: 'vertical',
      contents: [
        {
          type: 'text',
          text: user_text.to_s.empty? ? '(empty message)' : user_text.to_s,
          size: 'sm',
          wrap: true,
          color: '#666666'
        }
      ],
      paddingAll: 'md',
      backgroundColor: '#F5F5F5',
      cornerRadius: 'md'
    }

    # Add footer with timestamp
    contents << {
      type: 'box',
      layout: 'vertical',
      contents: [
        {
          type: 'text',
          text: Time.current.strftime('%Y-%m-%d %H:%M:%S'),
          size: 'xs',
          color: '#AAAAAA',
          align: 'center'
        }
      ],
      marginTop: 'md'
    }

    contents
  end
end
