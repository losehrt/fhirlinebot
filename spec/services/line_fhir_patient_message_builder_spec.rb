require 'rails_helper'

RSpec.describe LineFhirPatientMessageBuilder do
  describe '.build_patient_card' do
    let(:patient_data) do
      {
        id: 'p1',
        name: '測試患者',
        gender: '女性',
        birth_date: '1999-12-24',
        phone: '未提供',
        address: '未提供',
        identifiers: [
          { type: 'NNxxxx', value: 'G22****515' },
          { type: 'MR', value: 'G22****515' }
        ]
      }
    end

    it '返回有效的 Flex Message 結構' do
      result = described_class.build_patient_card(patient_data)

      expect(result[:type]).to eq('bubble')
      expect(result[:body]).to be_a(Hash)
      expect(result[:body][:type]).to eq('box')
      expect(result[:body][:layout]).to eq('vertical')
      expect(result[:body][:contents]).to be_an(Array)
    end

    it '包含患者標題和 ID' do
      result = described_class.build_patient_card(patient_data)
      contents = result[:body][:contents]

      # Find header section
      header = contents.find { |item| item[:type] == 'box' && item[:contents]&.any? { |c| c[:text]&.include?('FHIR 患者資訊') } }

      expect(header).to be_present
      expect(header[:contents][0][:text]).to eq('FHIR 患者資訊')
      expect(header[:contents][1][:text]).to include("ID: p1")
    end

    it '包含 FHIR Server URL' do
      result = described_class.build_patient_card(patient_data, 'https://hapi.fhir.tw/fhir')
      json_str = JSON.generate(result)

      expect(json_str).to include('Server:')
      expect(json_str).to include('https://hapi.fhir.tw/fhir')
    end

    it '當未提供 URL 時自動從配置取得' do
      allow(Rails.configuration).to receive(:fhir_server_url).and_return('https://test.fhir.server/fhir')
      result = described_class.build_patient_card(patient_data)
      json_str = JSON.generate(result)

      expect(json_str).to include('Server:')
      expect(json_str).to include('https://test.fhir.server/fhir')
    end

    it '包含患者詳細資訊' do
      result = described_class.build_patient_card(patient_data)
      contents = result[:body][:contents]

      # Verify that patient details are present
      json_str = JSON.generate(result)
      expect(json_str).to include('測試患者')
      expect(json_str).to include('女性')
      expect(json_str).to include('1999-12-24')
    end

    it '包含識別碼資訊' do
      result = described_class.build_patient_card(patient_data)
      contents = result[:body][:contents]

      json_str = JSON.generate(result)
      expect(json_str).to include('NNxxxx')
      expect(json_str).to include('G22****515')
    end

    it '包含資料來源聲明' do
      result = described_class.build_patient_card(patient_data)
      contents = result[:body][:contents]

      json_str = JSON.generate(result)
      expect(json_str).to include('資料來源聲明')
      expect(json_str).to include('FHIR 標準醫療資料伺服器')
      expect(json_str).to include('隨機方式抽取示例患者資料')
      expect(json_str).to include('演示用途')
    end

    it '包含更新時間' do
      result = described_class.build_patient_card(patient_data)
      contents = result[:body][:contents]

      json_str = JSON.generate(result)
      expect(json_str).to match(/更新時間: \d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}/)
    end

    it '不包含空文本欄位' do
      result = described_class.build_patient_card(patient_data)
      json_str = JSON.generate(result)

      expect(json_str).not_to include('"text":""')
    end

    context '當有空值時' do
      let(:patient_data_with_empty) do
        {
          id: 'p2',
          name: nil,
          gender: '',
          birth_date: '2000-01-01',
          phone: nil,
          address: '   ',
          identifiers: []
        }
      end

      it '使用「未提供」作為預設值' do
        result = described_class.build_patient_card(patient_data_with_empty)
        json_str = JSON.generate(result)

        expect(json_str).to include('未提供')
      end

      it '仍然包含資料來源聲明' do
        result = described_class.build_patient_card(patient_data_with_empty)
        json_str = JSON.generate(result)

        expect(json_str).to include('資料來源聲明')
        expect(json_str).to include('FHIR 標準醫療資料伺服器')
      end
    end

    context '當沒有識別碼時' do
      let(:patient_data_no_identifiers) do
        {
          id: 'p3',
          name: '患者名稱',
          gender: '男性',
          birth_date: '1995-05-15',
          phone: '未提供',
          address: '未提供',
          identifiers: []
        }
      end

      it '不包含識別碼區塊' do
        result = described_class.build_patient_card(patient_data_no_identifiers)
        contents = result[:body][:contents]

        # Count the number of boxes (should not have identifier box)
        boxes = contents.select { |item| item[:type] == 'box' }

        # Should have: header, details, footer (3 boxes minimum)
        expect(boxes.length).to be >= 3
      end

      it '仍然包含資料來源聲明' do
        result = described_class.build_patient_card(patient_data_no_identifiers)
        json_str = JSON.generate(result)

        expect(json_str).to include('資料來源聲明')
      end
    end
  end

  describe '.format_value_for_display' do
    it '保留非空值' do
      expect(described_class.send(:format_value_for_display, '測試')).to eq('測試')
    end

    it '清除空白字符' do
      expect(described_class.send(:format_value_for_display, '  測試  ')).to eq('測試')
    end

    it '對 nil 值返回「未提供」' do
      expect(described_class.send(:format_value_for_display, nil)).to eq('未提供')
    end

    it '對空字符串返回「未提供」' do
      expect(described_class.send(:format_value_for_display, '')).to eq('未提供')
    end

    it '對只有空白的字符串返回「未提供」' do
      expect(described_class.send(:format_value_for_display, '   ')).to eq('未提供')
    end

    it '將數字轉換為字符串後處理' do
      expect(described_class.send(:format_value_for_display, 123)).to eq('123')
    end
  end
end
