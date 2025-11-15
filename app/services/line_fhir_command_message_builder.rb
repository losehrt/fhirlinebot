# LineFhirCommandMessageBuilder - Build LINE Flex Messages for FHIR command menu
# Displays available FHIR commands in a rich format

class LineFhirCommandMessageBuilder
  # Define available FHIR commands
  FHIR_COMMANDS = [
    {
      command: 'patient',
      name: '取得患者資訊',
      description: '從 FHIR 伺服器隨機取得一位患者的詳細資訊'
    },
    {
      command: 'patient -a',
      name: '取得完整患者資訊',
      description: '取得包含姓名、性別、生日的患者資訊'
    },
    {
      command: 'encounter',
      name: '取得就診記錄',
      description: '從 FHIR 伺服器隨機取得一筆就診記錄 (即將推出)'
    }
  ].freeze

  # Build a Flex Message displaying available FHIR commands
  #
  # @return [Hash] Flex message container structure
  def self.build_command_menu
    Rails.logger.debug('[LineFhirCommandMessageBuilder] Building command menu')

    {
      type: 'bubble',
      body: {
        type: 'box',
        layout: 'vertical',
        contents: build_menu_contents,
        spacing: 'md',
        margin: 'md'
      }
    }
  end

  private

  def self.build_menu_contents
    contents = []

    # Header
    contents << {
      type: 'box',
      layout: 'vertical',
      contents: [
        {
          type: 'text',
          text: 'FHIR 功能選單',
          weight: 'bold',
          size: 'lg',
          color: '#1DB446'
        },
        {
          type: 'text',
          text: '可用的功能如下',
          size: 'xs',
          color: '#999999',
          margin: 'md'
        }
      ],
      margin: 'md'
    }

    # Separator
    contents << {
      type: 'separator',
      margin: 'md'
    }

    # Command items
    contents << {
      type: 'box',
      layout: 'vertical',
      contents: build_command_items,
      spacing: 'md',
      margin: 'md'
    }

    # Footer with disclaimer
    contents << {
      type: 'separator',
      margin: 'md'
    }

    contents << {
      type: 'box',
      layout: 'vertical',
      contents: [
        {
          type: 'text',
          text: '使用方式',
          size: 'xs',
          color: '#666666',
          weight: 'bold',
          margin: 'md'
        },
        {
          type: 'text',
          text: '請輸入 /fhir [功能] 來使用功能',
          size: 'xs',
          color: '#999999',
          wrap: true,
          margin: 'sm'
        },
        {
          type: 'text',
          text: '例如: /fhir patient',
          size: 'xs',
          color: '#999999',
          wrap: true,
          margin: 'sm'
        }
      ],
      margin: 'md'
    }

    contents
  end

  def self.build_command_items
    FHIR_COMMANDS.map do |cmd|
      build_command_item(cmd)
    end
  end

  def self.build_command_item(command)
    {
      type: 'box',
      layout: 'vertical',
      contents: [
        {
          type: 'box',
          layout: 'baseline',
          margin: 'none',
          contents: [
            {
              type: 'text',
              text: "/fhir #{command[:command]}",
              size: 'sm',
              color: '#1DB446',
              weight: 'bold',
              flex: 3
            },
            {
              type: 'text',
              text: command[:name],
              size: 'sm',
              color: '#666666',
              weight: 'bold',
              flex: 2,
              align: 'end'
            }
          ]
        },
        {
          type: 'text',
          text: command[:description],
          size: 'xs',
          color: '#999999',
          wrap: true,
          margin: 'md'
        }
      ],
      borderWidth: '1px',
      borderColor: '#e0e0e0',
      cornerRadius: 'md',
      paddingAll: 'md',
      backgroundColor: '#fafafa'
    }
  end
end
