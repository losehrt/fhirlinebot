# LineFhirPatientMessageBuilder - Build LINE Flex Messages for FHIR patient data
# Displays patient information in a rich format

class LineFhirPatientMessageBuilder
  # Build a flex message to display patient information
  #
  # @param patient_data [Hash] Formatted patient data from FhirPatientService
  # @param fhir_server_url [String] Optional FHIR server URL to display
  # @return [Hash] Flex message container structure
  def self.build_patient_card(patient_data, fhir_server_url = nil)
    Rails.logger.debug("[LineFhirPatientMessageBuilder] Building patient card for: #{patient_data[:id]}")

    # Get FHIR server URL if not provided
    fhir_server_url ||= get_fhir_server_url

    {
      type: 'bubble',
      body: {
        type: 'box',
        layout: 'vertical',
        contents: build_patient_contents(patient_data, fhir_server_url),
        spacing: 'md',
        margin: 'md'
      }
    }
  end

  private

  def self.build_patient_contents(patient_data, fhir_server_url = nil)
    contents = []

    # Header with patient ID and FHIR server URL
    header_contents = [
      {
        type: 'text',
        text: 'FHIR 患者資訊',
        weight: 'bold',
        size: 'lg',
        color: '#1DB446'
      },
      {
        type: 'text',
        text: "ID: #{patient_data[:id]}",
        size: 'xs',
        color: '#999999',
        margin: 'md'
      }
    ]

    # Add FHIR server URL if available
    if fhir_server_url.present?
      header_contents << {
        type: 'text',
        text: "Server: #{fhir_server_url}",
        size: 'xs',
        color: '#999999',
        margin: 'sm',
        wrap: true
      }
    end

    contents << {
      type: 'box',
      layout: 'vertical',
      contents: header_contents,
      margin: 'md'
    }

    # Separator
    contents << {
      type: 'separator',
      margin: 'md'
    }

    # Patient details
    contents << {
      type: 'box',
      layout: 'vertical',
      contents: build_detail_items(patient_data),
      spacing: 'sm',
      margin: 'md'
    }

    # Identifiers if any
    if patient_data[:identifiers].present? && patient_data[:identifiers].any?
      contents << {
        type: 'separator',
        margin: 'md'
      }

      contents << {
        type: 'box',
        layout: 'vertical',
        contents: build_identifier_items(patient_data[:identifiers]),
        spacing: 'sm',
        margin: 'md'
      }
    end

    # Footer with response time and disclaimer
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
          text: "回應時間: #{get_taipei_time.strftime('%Y-%m-%d %H:%M:%S')}",
          size: 'xs',
          color: '#999999',
          align: 'center'
        },
        {
          type: 'separator',
          margin: 'md'
        },
        {
          type: 'text',
          text: '資料來源聲明',
          size: 'xs',
          color: '#666666',
          weight: 'bold',
          margin: 'md'
        },
        {
          type: 'text',
          text: '本資訊來自 FHIR 標準醫療資料伺服器，採隨機方式抽取示例患者資料進行展示。',
          size: 'xs',
          color: '#999999',
          wrap: true,
          margin: 'sm'
        },
        {
          type: 'text',
          text: '此為演示用途，不代表真實患者資訊。如需實際醫療資訊，請聯絡醫療服務提供者。',
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

  def self.build_detail_items(patient_data)
    items = []

    # Name
    items << build_detail_item('姓名', patient_data[:name])

    # Gender
    items << build_detail_item('性別', patient_data[:gender])

    # Birth Date
    items << build_detail_item('生日', patient_data[:birth_date] || '未提供')

    # Phone
    items << build_detail_item('電話', patient_data[:phone])

    # Address
    items << build_detail_item('地址', patient_data[:address])

    items
  end

  def self.build_detail_item(label, value)
    # Ensure value is non-empty for LINE Flex Message API
    display_value = format_value_for_display(value)

    {
      type: 'box',
      layout: 'baseline',
      margin: 'sm',
      contents: [
        {
          type: 'text',
          text: label,
          color: '#aaaaaa',
          size: 'sm',
          flex: 2,
          weight: 'bold'
        },
        {
          type: 'text',
          text: display_value,
          wrap: true,
          color: '#666666',
          size: 'sm',
          flex: 5
        }
      ]
    }
  end

  def self.get_fhir_server_url
    # Get FHIR server URL from configuration
    if Rails.configuration.respond_to?(:fhir_server_url) && Rails.configuration.fhir_server_url.present?
      Rails.configuration.fhir_server_url
    else
      ENV['FHIR_SERVER_URL'] || 'https://hapi.fhir.tw/fhir'
    end
  end

  def self.get_taipei_time
    # Get current time in Asia/Taipei timezone
    Time.now.in_time_zone('Asia/Taipei')
  end

  def self.format_value_for_display(value)
    # Convert to string and strip whitespace
    str_value = value.to_s.strip

    # Return value if non-empty, otherwise return placeholder
    str_value.present? ? str_value : '未提供'
  end

  def self.build_identifier_items(identifiers)
    identifiers.map do |identifier|
      {
        type: 'box',
        layout: 'baseline',
        margin: 'sm',
        contents: [
          {
            type: 'text',
            text: format_value_for_display(identifier[:type]),
            color: '#aaaaaa',
            size: 'xs',
            flex: 2,
            weight: 'bold'
          },
          {
            type: 'text',
            text: format_value_for_display(identifier[:value]),
            wrap: true,
            color: '#666666',
            size: 'xs',
            flex: 5
          }
        ]
      }
    end
  end
end
