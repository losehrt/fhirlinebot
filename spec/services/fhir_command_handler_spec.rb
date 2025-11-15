require 'rails_helper'

RSpec.describe FhirCommandHandler do
  before do
    allow(Rails.configuration).to receive(:fhir_server_url).and_return('http://localhost:8080/fhir')
  end

  describe '.handle' do
    context 'with /fhir patient command' do
      it 'returns patient command result' do
        allow_any_instance_of(FhirPatientService).to receive(:get_random_patient).with(
          server: 'sandbox',
          complete_data: false
        ).and_return(FHIR::R4::Patient.new(id: 'p1', gender: 'male'))

        allow_any_instance_of(FhirPatientService).to receive(:format_patient_data).and_return(
          { id: 'p1', name: '測試', gender: '男性', birth_date: '2000-01-01', phone: '未提供', address: '未提供', identifiers: [] }
        )

        result = described_class.handle('/fhir patient')

        expect(result).to be_a(Hash)
        expect(result[:success]).to be true
        expect(result[:type]).to eq('flex')
        expect(result[:message]).to be_a(Hash)
        expect(result[:message][:type]).to eq('bubble')
      end

      it 'handles case insensitivity' do
        allow_any_instance_of(FhirPatientService).to receive(:get_random_patient).with(
          server: 'sandbox',
          complete_data: false
        ).and_return(FHIR::R4::Patient.new(id: 'p1'))

        allow_any_instance_of(FhirPatientService).to receive(:format_patient_data).and_return(
          { id: 'p1', name: '測試', gender: '男性', birth_date: '2000-01-01', phone: '未提供', address: '未提供', identifiers: [] }
        )

        result = described_class.handle('/FHIR PATIENT')

        expect(result[:success]).to be true
      end

      it 'handles patient not found' do
        allow_any_instance_of(FhirPatientService).to receive(:get_random_patient).with(
          server: 'sandbox',
          complete_data: false
        ).and_return(nil)

        result = described_class.handle('/fhir patient')

        expect(result[:success]).to be false
        expect(result[:type]).to eq('text')
        expect(result[:message]).to include('未能找到')
      end

      it 'handles FHIR service error' do
        allow_any_instance_of(FhirPatientService).to receive(:get_random_patient).with(
          server: 'sandbox',
          complete_data: false
        ).and_raise(Fhir::FhirServiceError, 'Connection failed')

        result = described_class.handle('/fhir patient')

        expect(result[:success]).to be false
        expect(result[:type]).to eq('text')
        expect(result[:message]).to include('FHIR 服務錯誤')
      end
    end

    context 'with /fhir encounter command' do
      it 'returns not implemented message' do
        result = described_class.handle('/fhir encounter')
        
        expect(result[:success]).to be false
        expect(result[:type]).to eq('text')
        expect(result[:message]).to include('尚未實現')
      end
    end

    context 'with /fhir help command' do
      it 'returns command menu as flex message' do
        result = described_class.handle('/fhir help')

        expect(result[:success]).to be true
        expect(result[:type]).to eq('flex')
        expect(result[:message][:type]).to eq('bubble')
      end

      it 'includes available commands in menu' do
        result = described_class.handle('/fhir help')
        json_str = JSON.generate(result[:message])

        expect(json_str).to include('FHIR 功能選單')
        expect(json_str).to include('/fhir patient')
        expect(json_str).to include('取得患者資訊')
      end
    end

    context 'with /fhir only' do
      it 'returns command menu as flex message' do
        result = described_class.handle('/fhir')

        expect(result[:success]).to be true
        expect(result[:type]).to eq('flex')
        expect(result[:message][:type]).to eq('bubble')
      end

      it 'includes usage instructions' do
        result = described_class.handle('/fhir')
        json_str = JSON.generate(result[:message])

        expect(json_str).to include('使用方式')
        expect(json_str).to include('請輸入 /fhir [功能] 來使用功能')
      end
    end

    context 'with /fhir patient -a flag' do
      it 'returns complete patient data' do
        allow_any_instance_of(FhirPatientService).to receive(:get_random_patient).with(
          server: 'sandbox',
          complete_data: true
        ).and_return(FHIR::R4::Patient.new(id: 'p1', gender: 'male'))

        allow_any_instance_of(FhirPatientService).to receive(:format_patient_data).and_return(
          { id: 'p1', name: '完整患者', gender: '男性', birth_date: '2000-01-01', phone: '0912-345-678', address: '台北市', identifiers: [] }
        )

        result = described_class.handle('/fhir patient -a')

        expect(result[:success]).to be true
        expect(result[:type]).to eq('flex')
      end

      it 'returns error when no complete patient found' do
        allow_any_instance_of(FhirPatientService).to receive(:get_random_patient).with(
          server: 'sandbox',
          complete_data: true
        ).and_return(nil)

        result = described_class.handle('/fhir patient -a')

        expect(result[:success]).to be false
        expect(result[:message]).to include('完整資料')
      end
    end

    context 'with unknown /fhir subcommand' do
      it 'returns error' do
        result = described_class.handle('/fhir unknown')

        expect(result[:error]).to include('未知的 FHIR 命令')
      end
    end

    context 'with non-FHIR command' do
      it 'returns nil' do
        result = described_class.handle('hello')

        expect(result).to be_nil
      end
    end

    context 'with extra whitespace' do
      it 'handles correctly' do
        allow_any_instance_of(FhirPatientService).to receive(:get_random_patient).with(
          server: 'sandbox',
          complete_data: false
        ).and_return(FHIR::R4::Patient.new(id: 'p1'))

        allow_any_instance_of(FhirPatientService).to receive(:format_patient_data).and_return(
          { id: 'p1', name: '測試', gender: '男性', birth_date: '2000-01-01', phone: '未提供', address: '未提供', identifiers: [] }
        )

        result = described_class.handle('  /fhir   patient  ')

        expect(result[:success]).to be true
      end
    end

    context 'with server selection -s flag' do
      it 'handles /fhir patient -s sandbox' do
        allow_any_instance_of(FhirPatientService).to receive(:get_random_patient).with(
          server: 'sandbox',
          complete_data: false
        ).and_return(FHIR::R4::Patient.new(id: 'p1'))

        allow_any_instance_of(FhirPatientService).to receive(:format_patient_data).and_return(
          { id: 'p1', name: '測試', gender: '男性', birth_date: '2000-01-01', phone: '未提供', address: '未提供', identifiers: [] }
        )

        result = described_class.handle('/fhir patient -s sandbox')

        expect(result[:success]).to be true
        expect(result[:type]).to eq('flex')
      end

      it 'handles /fhir patient -s hapi' do
        allow_any_instance_of(FhirPatientService).to receive(:get_random_patient).with(
          server: 'hapi',
          complete_data: false
        ).and_return(FHIR::R4::Patient.new(id: 'p1'))

        allow_any_instance_of(FhirPatientService).to receive(:format_patient_data).and_return(
          { id: 'p1', name: '測試', gender: '男性', birth_date: '2000-01-01', phone: '未提供', address: '未提供', identifiers: [] }
        )

        result = described_class.handle('/fhir patient -s hapi')

        expect(result[:success]).to be true
      end

      it 'handles long form --server flag' do
        allow_any_instance_of(FhirPatientService).to receive(:get_random_patient).with(
          server: 'sandbox',
          complete_data: false
        ).and_return(FHIR::R4::Patient.new(id: 'p1'))

        allow_any_instance_of(FhirPatientService).to receive(:format_patient_data).and_return(
          { id: 'p1', name: '測試', gender: '男性', birth_date: '2000-01-01', phone: '未提供', address: '未提供', identifiers: [] }
        )

        result = described_class.handle('/fhir patient --server sandbox')

        expect(result[:success]).to be true
      end

      it 'defaults to sandbox when no server specified' do
        allow_any_instance_of(FhirPatientService).to receive(:get_random_patient).with(
          server: 'sandbox',
          complete_data: false
        ).and_return(FHIR::R4::Patient.new(id: 'p1'))

        allow_any_instance_of(FhirPatientService).to receive(:format_patient_data).and_return(
          { id: 'p1', name: '測試', gender: '男性', birth_date: '2000-01-01', phone: '未提供', address: '未提供', identifiers: [] }
        )

        result = described_class.handle('/fhir patient')

        expect(result[:success]).to be true
      end

      it 'combines -s and -a flags' do
        allow_any_instance_of(FhirPatientService).to receive(:get_random_patient).with(
          server: 'hapi',
          complete_data: true
        ).and_return(FHIR::R4::Patient.new(id: 'p1'))

        allow_any_instance_of(FhirPatientService).to receive(:format_patient_data).and_return(
          { id: 'p1', name: '測試', gender: '男性', birth_date: '2000-01-01', phone: '0912-345-678', address: '台北市', identifiers: [] }
        )

        result = described_class.handle('/fhir patient -s hapi -a')

        expect(result[:success]).to be true
      end

      it 'handles invalid server alias' do
        result = described_class.handle('/fhir patient -s invalid_server')

        expect(result[:success]).to be false
        expect(result[:message]).to include('無效')
      end

      it 'handles case insensitive server alias' do
        allow_any_instance_of(FhirPatientService).to receive(:get_random_patient).with(
          server: 'sandbox',
          complete_data: false
        ).and_return(FHIR::R4::Patient.new(id: 'p1'))

        allow_any_instance_of(FhirPatientService).to receive(:format_patient_data).and_return(
          { id: 'p1', name: '測試', gender: '男性', birth_date: '2000-01-01', phone: '未提供', address: '未提供', identifiers: [] }
        )

        result = described_class.handle('/fhir patient -s SANDBOX')

        expect(result[:success]).to be true
      end

      it 'shows available servers in help when -s is mentioned' do
        result = described_class.handle('/fhir help')
        json_str = JSON.generate(result[:message])

        # Should mention available servers
        expect(json_str).to include('伺服器') # Chinese for server
      end
    end
  end
end
