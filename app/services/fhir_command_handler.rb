# FhirCommandHandler - Handle /fhir commands with various subcommands
#
# Supported commands:
#   /fhir patient              - Get a random patient from FHIR server
#   /fhir patient -a           - Get a random patient with complete data
#   /fhir patient -s sandbox   - Get patient from specific FHIR server (sandbox, hapi, local)
#   /fhir patient -s hapi -a   - Combine server selection with complete data flag
#   /fhir encounter            - Get a random encounter (future)
#   /fhir help                 - Show available FHIR commands

class FhirCommandHandler
  def self.handle(text)
    command_line = text.to_s.strip.downcase

    # Check if it's a /fhir command
    return nil unless command_line.start_with?('/fhir')

    # Parse the command
    parts = command_line.split(/\s+/)

    # parts[0] = '/fhir'
    subcommand = parts[1]&.downcase

    case subcommand
    when 'patient'
      handle_patient_command(parts)
    when 'encounter'
      handle_encounter_command
    when 'help', nil
      handle_help_command
    else
      { error: "未知的 FHIR 命令: #{subcommand}" }
    end
  end

  private

  def self.handle_patient_command(parts)
    request_id = SecureRandom.hex(8)
    timestamp = Time.now.in_time_zone('Asia/Taipei').strftime('%Y-%m-%d %H:%M:%S')

    # Parse flags from command parts
    server = extract_server_alias(parts)
    complete_data = parts.include?('-a')

    Rails.logger.info("[FhirCommandHandler][#{request_id}] Handling /fhir patient command at #{timestamp} (server: #{server}, complete_data: #{complete_data})")

    begin
      # Validate server alias
      unless FhirServerRegistry.valid_alias?(server)
        return {
          success: false,
          type: 'text',
          message: "無效的伺服器別名: #{server}。可用的伺服器: #{FhirServerRegistry.aliases.join(', ')}"
        }
      end

      fhir_service = FhirPatientService.new
      patient = fhir_service.get_random_patient(server: server, complete_data: complete_data)

      if patient
        patient_data = fhir_service.format_patient_data(patient)
        Rails.logger.info("[FhirCommandHandler][#{request_id}] Got patient: #{patient.id} - #{patient_data[:name]}")

        flex_message = LineFhirPatientMessageBuilder.build_patient_card(patient_data)

        {
          success: true,
          type: 'flex',
          message: flex_message
        }
      else
        error_msg = complete_data ? '未能找到完整資料的患者' : '未能找到患者資料'
        Rails.logger.warn("[FhirCommandHandler][#{request_id}] No patient found: #{error_msg}")
        {
          success: false,
          type: 'text',
          message: error_msg
        }
      end
    rescue Fhir::FhirServiceError => e
      Rails.logger.error("[FhirCommandHandler][#{request_id}] FHIR error: #{e.message}")
      {
        success: false,
        type: 'text',
        message: "FHIR 服務錯誤: #{e.message}"
      }
    rescue StandardError => e
      Rails.logger.error("[FhirCommandHandler][#{request_id}] Error: #{e.class} - #{e.message}")
      {
        success: false,
        type: 'text',
        message: '發生錯誤，無法取得患者資料'
      }
    end
  end

  # Extract server alias from command parts
  #
  # @param parts [Array<String>] Command parts split by whitespace
  # @return [String] Server alias (defaults to 'sandbox')
  def self.extract_server_alias(parts)
    # Look for -s or --server flag
    short_index = parts.find_index('-s')
    long_index = parts.find_index('--server')

    if short_index && parts[short_index + 1]
      parts[short_index + 1]
    elsif long_index && parts[long_index + 1]
      parts[long_index + 1]
    else
      FhirServerRegistry.default_server
    end
  end

  def self.handle_encounter_command
    Rails.logger.info('[FhirCommandHandler] Handling /fhir encounter command')
    
    {
      success: false,
      type: 'text',
      message: '功能尚未實現: Encounter 命令'
    }
  end

  def self.handle_help_command
    Rails.logger.info('[FhirCommandHandler] Handling /fhir help command')

    flex_message = LineFhirCommandMessageBuilder.build_command_menu

    {
      success: true,
      type: 'flex',
      message: flex_message
    }
  end
end
