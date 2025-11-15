require 'rails_helper'

RSpec.describe Fhir::ClientService do
  let(:fhir_server_url) { 'http://localhost:8080/fhir' }
  let(:client_double) { double('FHIR::Client') }

  before do
    allow(Rails.configuration).to receive(:fhir_server_url).and_return(fhir_server_url)
    allow(FHIR::Client).to receive(:new).with(fhir_server_url).and_return(client_double)
  end

  # Helper to create FHIR resources with proper versioning
  def build_patient(id, name_given = 'John', name_family = 'Doe')
    FHIR::R4::Patient.new(
      id: id,
      name: [FHIR::R4::HumanName.new(given: [name_given], family: name_family)]
    )
  end

  def build_observation(id, code = '8480-6')
    FHIR::R4::Observation.new(
      id: id,
      code: FHIR::R4::CodeableConcept.new(
        coding: [FHIR::R4::Coding.new(code: code)]
      )
    )
  end

  def build_condition(id)
    FHIR::R4::Condition.new(id: id)
  end

  def build_medication(id)
    FHIR::R4::MedicationStatement.new(id: id)
  end

  def build_bundle(*resources)
    entries = resources.map { |resource| FHIR::R4::Bundle::Entry.new(resource: resource) }
    FHIR::R4::Bundle.new(entry: entries)
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

    it 'returns a FHIR Patient resource' do
      patient_resource = build_patient(patient_id)
      patient_resource.birthDate = '1980-01-01'
      reply = double('FHIR::ClientReply', resource: patient_resource)
      allow(client_double).to receive(:read).with(FHIR::Patient, patient_id).and_return(reply)

      patient = service.find_patient(patient_id)

      expect(patient).to be_a(FHIR::R4::Patient)
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
      patient1 = build_patient('p1', 'John', 'Doe')
      patient2 = build_patient('p2', 'John', 'Smith')
      bundle = build_bundle(patient1, patient2)

      reply = double('FHIR::ClientReply', resource: bundle)
      allow(client_double).to receive(:search).with(FHIR::Patient, search: search_criteria).and_return(reply)

      patients = service.search_patients(search_criteria)

      expect(patients).to be_an(Array)
      expect(patients.length).to eq(2)
      expect(patients.all? { |p| p.is_a?(FHIR::R4::Patient) }).to be true
    end

    it 'returns empty array when no results found' do
      bundle = build_bundle()

      reply = double('FHIR::ClientReply', resource: bundle)
      allow(client_double).to receive(:search).with(FHIR::Patient, search: search_criteria).and_return(reply)

      patients = service.search_patients(search_criteria)

      expect(patients).to eq([])
    end
  end

  describe '#find_observations' do
    let(:service) { described_class.new }
    let(:patient_id) { 'patient-123' }

    it 'returns array of Observation resources for a patient' do
      obs = build_observation('obs-1')
      bundle = build_bundle(obs)

      reply = double('FHIR::ClientReply', resource: bundle)
      allow(client_double).to receive(:search).with(FHIR::Observation, search: { patient: patient_id })
        .and_return(reply)

      observations = service.find_observations(patient_id)

      expect(observations).to be_an(Array)
      expect(observations.first).to be_a(FHIR::R4::Observation)
    end

    it 'filters by code when provided' do
      bundle = build_bundle()

      code = '8480-6'
      reply = double('FHIR::ClientReply', resource: bundle)
      allow(client_double).to receive(:search).with(FHIR::Observation, search: { patient: patient_id, code: code })
        .and_return(reply)

      observations = service.find_observations(patient_id, code: code)

      expect(observations).to eq([])
    end

    it 'returns empty array when no observations found' do
      bundle = build_bundle()

      reply = double('FHIR::ClientReply', resource: bundle)
      allow(client_double).to receive(:search).with(FHIR::Observation, search: { patient: patient_id })
        .and_return(reply)

      observations = service.find_observations(patient_id)

      expect(observations).to eq([])
    end
  end

  describe '#find_conditions' do
    let(:service) { described_class.new }
    let(:patient_id) { 'patient-123' }

    it 'returns array of Condition resources' do
      condition = build_condition('cond-1')
      bundle = build_bundle(condition)

      reply = double('FHIR::ClientReply', resource: bundle)
      allow(client_double).to receive(:search).with(FHIR::Condition, search: { patient: patient_id })
        .and_return(reply)

      conditions = service.find_conditions(patient_id)

      expect(conditions).to be_an(Array)
      expect(conditions.first).to be_a(FHIR::R4::Condition)
    end
  end

  describe '#find_medications' do
    let(:service) { described_class.new }
    let(:patient_id) { 'patient-123' }

    it 'returns array of MedicationStatement resources' do
      med = build_medication('med-1')
      bundle = build_bundle(med)

      reply = double('FHIR::ClientReply', resource: bundle)
      allow(client_double).to receive(:search).with(FHIR::MedicationStatement, search: { patient: patient_id })
        .and_return(reply)

      medications = service.find_medications(patient_id)

      expect(medications).to be_an(Array)
      expect(medications.first).to be_a(FHIR::R4::MedicationStatement)
    end
  end
end
