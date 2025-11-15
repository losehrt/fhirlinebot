# FhirCommandHandler - Handle /fhir commands with various subcommands
# 
# Supported commands:
#   /fhir patient  - Get a random patient from FHIR server
#   /fhir encounter - Get a random encounter (future)
#   /fhir help - Show available FHIR commands

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
      handle_patient_command
    when 'encounter'
      handle_encounter_command
    when 'help', nil
      handle_help_command
    else
      { error: "未知的 FHIR 命令: #{subcommand}" }
    end
  end

  private

  def self.handle_patient_command
    Rails.logger.info('[FhirCommandHandler] Handling /fhir patient command')
    
    begin
      fhir_service = FhirPatientService.new
      patient = fhir_service.get_random_patient
      
      if patient
        patient_data = fhir_service.format_patient_data(patient)
        flex_message = LineFhirPatientMessageBuilder.build_patient_card(patient_data)
        
        {
          success: true,
          type: 'flex',
          message: flex_message
        }
      else
        {
          success: false,
          type: 'text',
          message: '未能找到患者資料'
        }
      end
    rescue Fhir::FhirServiceError => e
      Rails.logger.error("[FhirCommandHandler] FHIR error: #{e.message}")
      {
        success: false,
        type: 'text',
        message: "FHIR 服務錯誤: #{e.message}"
      }
    rescue StandardError => e
      Rails.logger.error("[FhirCommandHandler] Error: #{e.class} - #{e.message}")
      {
        success: false,
        type: 'text',
        message: '發生錯誤，無法取得患者資料'
      }
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
    
    help_text = <<~TEXT
      FHIR 命令幫助
      
      可用的命令:
      • /fhir patient - 取得隨機患者資訊
      • /fhir encounter - 取得隨機就診記錄 (尚未實現)
      • /fhir help - 顯示此幫助信息
    TEXT
    
    {
      success: true,
      type: 'text',
      message: help_text.strip
    }
  end
end
