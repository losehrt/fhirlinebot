require 'rails_helper'

RSpec.describe Fhir::ClientService do
  let(:fhir_server_url) { 'http://localhost:8080/fhir' }
  let(:client_double) { double('FHIR::Client') }

  before do
    allow(Rails.configuration).to receive(:fhir_server_url).and_return(fhir_server_url)
    allow(FHIR::Client).to receive(:new).with(fhir_server_url).and_return(client_double)
  end

  describe '#initialize' do
    it 'creates a client with the configured FHIR server URL' do
      service = described_class.new
      expect(service.server_url).to eq(fhir_server_url)
    end

    it 'uses organization-specific FHIR server URL when provided' do
      org_url = 'https://fhir.hospital.com'
      config = double(server_url: org_url)
      allow(FhirConfiguration).to receive(:for_organization).with(123).and_return(config)
      allow(FHIR::Client).to receive(:new).with(org_url).and_return(client_double)

      service = described_class.new(organization_id: 123)
      expect(service.server_url).to eq(org_url)
    end
  end

  describe '#find_patient' do
    let(:service) { described_class.new }
    let(:patient_id) { 'patient-123' }
    let(:patient_resource) do
      patient = FHIR::Patient.new
      patient.id = patient_id
      patient.name = [FHIR::HumanName.new(given: ['John'], family: 'Doe')]
      patient.birthDate = '1980-01-01'
      patient
    end

    it 'returns a FHIR Patient resource' do
      allow(client_double).to receive(:read).with(FHIR::Patient, patient_id).and_return(patient_resource)

      patient = service.find_patient(patient_id)

      expect(patient).to be_a(FHIR::Patient)
      expect(patient.id).to eq(patient_id)
    end

    it 'raises FhirServiceError on errors' do
      allow(client_double).to receive(:read).with(FHIR::Patient, patient_id).and_raise(StandardError, 'Connection failed')

      expect {
        service.find_patient(patient_id)
      }.to raise_error(Fhir::FhirServiceError)
    end
  end

  describe '#search_patients' do
    let(:service) { described_class.new }
    let(:search_criteria) { { name: 'John' } }

    it 'returns array of Patient resources' do
      bundle = FHIR::Bundle.new
      patient1 = FHIR::Patient.new(id: 'p1', name: [FHIR::HumanName.new(given: ['John'], family: 'Doe')])
      patient2 = FHIR::Patient.new(id: 'p2', name: [FHIR::HumanName.new(given: ['John'], family: 'Smith')])

      entry1 = FHIR::Bundle::Entry.new(resource: patient1)
      entry2 = FHIR::Bundle::Entry.new(resource: patient2)
      bundle.entry = [entry1, entry2]

      allow(client_double).to receive(:search).with(FHIR::Patient, search: search_criteria).and_return(bundle)

      patients = service.search_patients(search_criteria)

      expect(patients).to be_an(Array)
      expect(patients.length).to eq(2)
      expect(patients.all? { |p| p.is_a?(FHIR::Patient) }).to be true
    end

    it 'returns empty array when no results found' do
      bundle = FHIR::Bundle.new
      bundle.entry = []

      allow(client_double).to receive(:search).with(FHIR::Patient, search: search_criteria).and_return(bundle)

      patients = service.search_patients(search_criteria)

      expect(patients).to eq([])
    end
  end

  describe '#find_observations' do
    let(:service) { described_class.new }
    let(:patient_id) { 'patient-123' }

    it 'returns array of Observation resources for a patient' do
      bundle = FHIR::Bundle.new
      obs = FHIR::Observation.new(
        id: 'obs-1',
        code: FHIR::CodeableConcept.new(coding: [FHIR::Coding.new(code: '8480-6')])
      )
      entry = FHIR::Bundle::Entry.new(resource: obs)
      bundle.entry = [entry]

      allow(client_double).to receive(:search).with(FHIR::Observation, search: { patient: patient_id })
        .and_return(bundle)

      observations = service.find_observations(patient_id)

      expect(observations).to be_an(Array)
      expect(observations.first).to be_a(FHIR::Observation)
    end

    it 'filters by code when provided' do
      bundle = FHIR::Bundle.new
      bundle.entry = []

      code = '8480-6'
      allow(client_double).to receive(:search).with(FHIR::Observation, search: { patient: patient_id, code: code })
        .and_return(bundle)

      observations = service.find_observations(patient_id, code: code)

      expect(observations).to eq([])
    end

    it 'returns empty array when no observations found' do
      bundle = FHIR::Bundle.new
      bundle.entry = []

      allow(client_double).to receive(:search).with(FHIR::Observation, search: { patient: patient_id })
        .and_return(bundle)

      observations = service.find_observations(patient_id)

      expect(observations).to eq([])
    end
  end

  describe '#find_conditions' do
    let(:service) { described_class.new }
    let(:patient_id) { 'patient-123' }

    it 'returns array of Condition resources' do
      bundle = FHIR::Bundle.new
      condition = FHIR::Condition.new(id: 'cond-1')
      entry = FHIR::Bundle::Entry.new(resource: condition)
      bundle.entry = [entry]

      allow(client_double).to receive(:search).with(FHIR::Condition, search: { patient: patient_id })
        .and_return(bundle)

      conditions = service.find_conditions(patient_id)

      expect(conditions).to be_an(Array)
      expect(conditions.first).to be_a(FHIR::Condition)
    end
  end

  describe '#find_medications' do
    let(:service) { described_class.new }
    let(:patient_id) { 'patient-123' }

    it 'returns array of MedicationStatement resources' do
      bundle = FHIR::Bundle.new
      med = FHIR::MedicationStatement.new(id: 'med-1')
      entry = FHIR::Bundle::Entry.new(resource: med)
      bundle.entry = [entry]

      allow(client_double).to receive(:search).with(FHIR::MedicationStatement, search: { patient: patient_id })
        .and_return(bundle)

      medications = service.find_medications(patient_id)

      expect(medications).to be_an(Array)
      expect(medications.first).to be_a(FHIR::MedicationStatement)
    end
  end
end
