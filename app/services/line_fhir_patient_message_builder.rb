# LineFhirPatientMessageBuilder - Build LINE Flex Messages for FHIR patient data
# Displays patient information in a rich format

class LineFhirPatientMessageBuilder
  # Build a flex message to display patient information
  #
  # @param patient_data [Hash] Formatted patient data from FhirPatientService
  # @return [Hash] Flex message container structure
  def self.build_patient_card(patient_data)
    Rails.logger.debug("[LineFhirPatientMessageBuilder] Building patient card for: #{patient_data[:id]}")

    {
      type: 'bubble',
      body: {
        type: 'box',
        layout: 'vertical',
        contents: build_patient_contents(patient_data),
        spacing: 'md',
        margin: 'md'
      }
    }
  end

  private

  def self.build_patient_contents(patient_data)
    contents = []

    # Header with patient ID
    contents << {
      type: 'box',
      layout: 'vertical',
      contents: [
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
      ],
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

    # Footer
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
          text: "更新時間: #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}",
          size: 'xs',
          color: '#999999',
          align: 'center'
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
          text: value.to_s,
          wrap: true,
          color: '#666666',
          size: 'sm',
          flex: 5
        }
      ]
    }
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
            text: identifier[:type],
            color: '#aaaaaa',
            size: 'xs',
            flex: 2,
            weight: 'bold'
          },
          {
            type: 'text',
            text: identifier[:value],
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
