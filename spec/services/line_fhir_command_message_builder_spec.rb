require 'rails_helper'

RSpec.describe LineFhirCommandMessageBuilder do
  describe '.build_command_menu' do
    it '返回有效的 Flex Message 結構' do
      result = described_class.build_command_menu

      expect(result[:type]).to eq('bubble')
      expect(result[:body]).to be_a(Hash)
      expect(result[:body][:type]).to eq('box')
      expect(result[:body][:layout]).to eq('vertical')
      expect(result[:body][:contents]).to be_an(Array)
    end

    it '包含功能選單標題' do
      result = described_class.build_command_menu
      json_str = JSON.generate(result)

      expect(json_str).to include('FHIR 功能選單')
      expect(json_str).to include('可用的功能如下')
    end

    it '包含所有可用命令' do
      result = described_class.build_command_menu
      json_str = JSON.generate(result)

      expect(json_str).to include('/fhir patient')
      expect(json_str).to include('取得患者資訊')
      expect(json_str).to include('從 FHIR 伺服器隨機取得一位患者的詳細資訊')
    end

    it '包含 -a 旗標說明' do
      result = described_class.build_command_menu
      json_str = JSON.generate(result)

      expect(json_str).to include('/fhir patient -a')
      expect(json_str).to include('取得完整患者資訊')
      expect(json_str).to include('包含姓名、性別、生日、電話、地址')
    end

    it '包含尚未推出的命令' do
      result = described_class.build_command_menu
      json_str = JSON.generate(result)

      expect(json_str).to include('/fhir encounter')
      expect(json_str).to include('取得就診記錄')
      expect(json_str).to include('即將推出')
    end

    it '包含使用方式說明' do
      result = described_class.build_command_menu
      json_str = JSON.generate(result)

      expect(json_str).to include('使用方式')
      expect(json_str).to include('請輸入 /fhir [功能] 來使用功能')
      expect(json_str).to include('例如: /fhir patient')
    end

    it '包含綠色標題' do
      result = described_class.build_command_menu
      json_str = JSON.generate(result)

      expect(json_str).to include('#1DB446')
    end

    it '包含分隔線' do
      result = described_class.build_command_menu
      contents = result[:body][:contents]

      separator_count = contents.count { |item| item[:type] == 'separator' }
      expect(separator_count).to be >= 2
    end

    it '不包含空文本欄位' do
      result = described_class.build_command_menu
      json_str = JSON.generate(result)

      expect(json_str).not_to include('"text":""')
    end

    it '命令項目有邊框樣式' do
      result = described_class.build_command_menu
      json_str = JSON.generate(result)

      expect(json_str).to include('borderWidth')
      expect(json_str).to include('borderColor')
      expect(json_str).to include('cornerRadius')
    end

    it '命令項目有背景色' do
      result = described_class.build_command_menu
      json_str = JSON.generate(result)

      expect(json_str).to include('#fafafa')
    end
  end

  describe 'FHIR_COMMANDS 常數' do
    it '定義了 patient 命令' do
      patient_cmd = described_class::FHIR_COMMANDS.find { |cmd| cmd[:command] == 'patient' }

      expect(patient_cmd).to be_present
      expect(patient_cmd[:name]).to eq('取得患者資訊')
    end

    it '定義了 patient -a 命令' do
      patient_complete_cmd = described_class::FHIR_COMMANDS.find { |cmd| cmd[:command] == 'patient -a' }

      expect(patient_complete_cmd).to be_present
      expect(patient_complete_cmd[:name]).to eq('取得完整患者資訊')
      expect(patient_complete_cmd[:description]).to include('姓名、性別、生日、電話、地址')
    end

    it '定義了 encounter 命令' do
      encounter_cmd = described_class::FHIR_COMMANDS.find { |cmd| cmd[:command] == 'encounter' }

      expect(encounter_cmd).to be_present
      expect(encounter_cmd[:name]).to eq('取得就診記錄')
    end

    it '每個命令都有完整的信息' do
      described_class::FHIR_COMMANDS.each do |cmd|
        expect(cmd).to have_key(:command)
        expect(cmd).to have_key(:name)
        expect(cmd).to have_key(:description)
        expect(cmd[:command]).to be_a(String)
        expect(cmd[:name]).to be_a(String)
        expect(cmd[:description]).to be_a(String)
      end
    end
  end
end
