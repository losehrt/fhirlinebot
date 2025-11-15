require 'rails_helper'

RSpec.describe FhirPatientService do
  let(:fhir_server_url) { 'http://localhost:8080/fhir' }
  let(:client_double) { double('FHIR::Client') }
  let(:service) { described_class.new }

  before do
    allow(Rails.configuration).to receive(:fhir_server_url).and_return(fhir_server_url)
    allow(FHIR::Client).to receive(:new).with(fhir_server_url).and_return(client_double)
  end

  describe '#get_random_patient' do
    it 'returns a random patient from search results' do
      patient1 = FHIR::R4::Patient.new(id: 'p1', name: [FHIR::R4::HumanName.new(given: ['John'], family: 'Doe')])
      patient2 = FHIR::R4::Patient.new(id: 'p2', name: [FHIR::R4::HumanName.new(given: ['Jane'], family: 'Smith')])

      bundle = FHIR::R4::Bundle.new(
        entry: [
          FHIR::R4::Bundle::Entry.new(resource: patient1),
          FHIR::R4::Bundle::Entry.new(resource: patient2)
        ]
      )

      reply = double('FHIR::ClientReply', resource: bundle)
      allow_any_instance_of(Fhir::ClientService).to receive(:search_patients).and_return([patient1, patient2])

      random_patient = service.get_random_patient
      expect([patient1.id, patient2.id]).to include(random_patient.id)
    end

    it 'filters out patients without names' do
      patient_with_name = FHIR::R4::Patient.new(id: 'p1', name: [FHIR::R4::HumanName.new(given: ['John'], family: 'Doe')])
      patient_without_name = FHIR::R4::Patient.new(id: 'p2')
      patient_with_empty_name = FHIR::R4::Patient.new(id: 'p3', name: [FHIR::R4::HumanName.new(given: [], family: '')])

      allow_any_instance_of(Fhir::ClientService).to receive(:search_patients).and_return([
        patient_with_name,
        patient_without_name,
        patient_with_empty_name
      ])

      random_patient = service.get_random_patient

      expect(random_patient).not_to be_nil
      expect(random_patient.id).to eq('p1')
    end

    it 'retries when first batch has no patients with names' do
      patient_without_name1 = FHIR::R4::Patient.new(id: 'p1')
      patient_without_name2 = FHIR::R4::Patient.new(id: 'p2')
      patient_with_name = FHIR::R4::Patient.new(id: 'p3', name: [FHIR::R4::HumanName.new(given: ['John'], family: 'Doe')])

      allow_any_instance_of(Fhir::ClientService).to receive(:search_patients).and_return(
        [patient_without_name1, patient_without_name2],
        [patient_with_name]
      )

      random_patient = service.get_random_patient

      expect(random_patient).not_to be_nil
      expect(random_patient.id).to eq('p3')
    end

    it 'returns nil when no patients found' do
      allow_any_instance_of(Fhir::ClientService).to receive(:search_patients).and_return([])

      result = service.get_random_patient
      expect(result).to be_nil
    end

    it 'raises FhirServiceError on FHIR service error' do
      allow_any_instance_of(Fhir::ClientService).to receive(:search_patients).and_raise(Fhir::FhirServiceError, 'Connection failed')

      expect {
        service.get_random_patient
      }.to raise_error(Fhir::FhirServiceError)
    end
  end

  describe '#format_patient_data' do
    let(:patient) do
      FHIR::R4::Patient.new(
        id: 'patient-123',
        name: [FHIR::R4::HumanName.new(given: ['John'], family: 'Doe')],
        gender: 'male',
        birthDate: '1980-01-01',
        telecom: [FHIR::R4::ContactPoint.new(system: 'phone', value: '0912-345-678')],
        address: [
          FHIR::R4::Address.new(
            country: 'TW',
            state: 'Taiwan',
            city: 'Taipei',
            district: 'Songshan'
          )
        ],
        identifier: [
          FHIR::R4::Identifier.new(
            type: FHIR::R4::CodeableConcept.new(text: 'National ID'),
            value: 'A123456789'
          )
        ]
      )
    end

    it 'formats patient data correctly' do
      data = service.format_patient_data(patient)

      expect(data[:id]).to eq('patient-123')
      expect(data[:name]).to eq('Doe John')
      expect(data[:gender]).to eq('男性')
      expect(data[:birth_date]).to eq('1980-01-01')
      expect(data[:phone]).to eq('0912-345-678')
      expect(data[:address]).to include('Taipei')
      expect(data[:identifiers]).to be_an(Array)
      expect(data[:identifiers].first[:value]).to eq('A123456789')
    end

    it 'handles missing data gracefully' do
      patient = FHIR::R4::Patient.new(id: 'patient-456')
      data = service.format_patient_data(patient)

      expect(data[:id]).to eq('patient-456')
      expect(data[:name]).to eq('未提供')
      expect(data[:phone]).to eq('未提供')
      expect(data[:address]).to eq('未提供')
      expect(data[:identifiers]).to eq([])
    end

    it 'translates gender codes to Chinese' do
      test_cases = {
        'male' => '男性',
        'female' => '女性',
        'other' => '其他',
        'unknown' => '未知'
      }

      test_cases.each do |code, chinese|
        patient = FHIR::R4::Patient.new(id: 'p', gender: code)
        data = service.format_patient_data(patient)
        expect(data[:gender]).to eq(chinese)
      end
    end
  end
end
