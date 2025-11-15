# Fhir::ClientService - Handle all FHIR server communications
# Abstracts away FHIR client library details and provides a clean interface
# for querying FHIR resources (Patient, Observation, etc.)
#
# Usage:
#   service = Fhir::ClientService.new
#   patient = service.find_patient('patient-123')
#   observations = service.find_observations('patient-123', code: '8480-6')

require_relative 'errors'

module Fhir
  class ClientService
    attr_reader :server_url

    # Initialize FHIR client service
    #
    # @param organization_id [Integer, nil] Organization ID for multi-tenant support
    # @raise [FhirServiceError] if no FHIR server URL is configured
    def initialize(organization_id: nil)
      @server_url = load_server_url(organization_id)
      @client = FHIR::Client.new(@server_url)
      validate_configuration!
    end

    # Find a patient by ID
    #
    # @param patient_id [String] FHIR Patient resource ID
    # @return [FHIR::Patient] Patient resource
    # @raise [FhirResourceNotFoundError] if patient not found
    # @raise [FhirServiceError] on other errors
    def find_patient(patient_id)
      Rails.logger.info("[FHIR] Finding patient: #{patient_id}")

      reply = @client.read(FHIR::Patient, patient_id)
      resource = extract_resource_from_reply(reply)
      validate_resource(resource, FHIR::Patient)

      Rails.logger.debug("[FHIR] Patient found: #{patient_id}")
      resource
    rescue StandardError => e
      Rails.logger.error("[FHIR] Error finding patient: #{e.class} - #{e.message}")
      raise FhirServiceError, "Failed to find patient: #{e.message}"
    end

    # Search for patients by criteria
    #
    # @param criteria [Hash] Search parameters (e.g., name, birthdate, identifier)
    # @return [Array<FHIR::Patient>] Array of matching patient resources
    # @raise [FhirServiceError] on errors
    def search_patients(criteria)
      Rails.logger.info("[FHIR] Searching patients with criteria: #{criteria}")

      reply = @client.search(FHIR::Patient, search: criteria)
      bundle = extract_resource_from_reply(reply)
      patients = extract_resources(bundle, FHIR::Patient)

      Rails.logger.info("[FHIR] Found #{patients.count} patients")
      patients
    rescue StandardError => e
      Rails.logger.error("[FHIR] Error searching patients: #{e.class} - #{e.message}")
      raise FhirServiceError, "Failed to search patients: #{e.message}"
    end

    # Find observations for a patient
    #
    # @param patient_id [String] FHIR Patient resource ID
    # @param code [String, nil] Optional FHIR observation code (LOINC)
    # @return [Array<FHIR::Observation>] Array of observation resources
    # @raise [FhirServiceError] on errors
    def find_observations(patient_id, code: nil)
      Rails.logger.info("[FHIR] Finding observations for patient: #{patient_id}, code: #{code}")

      criteria = { patient: patient_id }
      criteria[:code] = code if code.present?

      reply = @client.search(FHIR::Observation, search: criteria)
      bundle = extract_resource_from_reply(reply)
      observations = extract_resources(bundle, FHIR::Observation)

      Rails.logger.info("[FHIR] Found #{observations.count} observations")
      observations
    rescue StandardError => e
      Rails.logger.error("[FHIR] Error finding observations: #{e.class} - #{e.message}")
      raise FhirServiceError, "Failed to find observations: #{e.message}"
    end

    # Find conditions (diagnoses) for a patient
    #
    # @param patient_id [String] FHIR Patient resource ID
    # @return [Array<FHIR::Condition>] Array of condition resources
    # @raise [FhirServiceError] on errors
    def find_conditions(patient_id)
      Rails.logger.info("[FHIR] Finding conditions for patient: #{patient_id}")

      reply = @client.search(FHIR::Condition, search: { patient: patient_id })
      bundle = extract_resource_from_reply(reply)
      conditions = extract_resources(bundle, FHIR::Condition)

      Rails.logger.info("[FHIR] Found #{conditions.count} conditions")
      conditions
    rescue StandardError => e
      Rails.logger.error("[FHIR] Error finding conditions: #{e.class} - #{e.message}")
      raise FhirServiceError, "Failed to find conditions: #{e.message}"
    end

    # Find medications for a patient
    #
    # @param patient_id [String] FHIR Patient resource ID
    # @return [Array<Hash>] Array of medication statements with medication info
    # @raise [FhirServiceError] on errors
    def find_medications(patient_id)
      Rails.logger.info("[FHIR] Finding medications for patient: #{patient_id}")

      reply = @client.search(FHIR::MedicationStatement, search: { patient: patient_id })
      bundle = extract_resource_from_reply(reply)
      medications = extract_resources(bundle, FHIR::MedicationStatement)

      Rails.logger.info("[FHIR] Found #{medications.count} medications")
      medications
    rescue StandardError => e
      Rails.logger.error("[FHIR] Error finding medications: #{e.class} - #{e.message}")
      raise FhirServiceError, "Failed to find medications: #{e.message}"
    end

    private

    # Load FHIR server URL from configuration
    #
    # Priority:
    # 1. Organization-specific FhirConfiguration
    # 2. Environment variable FHIR_SERVER_URL
    # 3. Rails.configuration.fhir_server_url (if defined)
    #
    # @param organization_id [Integer, nil] Organization ID
    # @return [String] FHIR server URL
    def load_server_url(organization_id)
      if organization_id.present?
        config = FhirConfiguration.for_organization(organization_id)
        return config.server_url if config&.server_url.present?
      end

      ENV['FHIR_SERVER_URL'] ||
        (Rails.configuration.respond_to?(:fhir_server_url) && Rails.configuration.fhir_server_url)
    end

    # Validate service configuration
    #
    # @raise [FhirServiceError] if server URL is not configured
    def validate_configuration!
      return if @server_url.present?

      raise FhirServiceError, 'FHIR server URL not configured. Set FHIR_SERVER_URL environment variable or configure in Rails.configuration.fhir_server_url'
    end

    # Extract resource from FHIR ClientReply wrapper
    #
    # FHIR client library wraps all responses in ClientReply objects.
    # This method extracts the actual resource from the wrapper.
    #
    # @param reply [FHIR::ClientReply] The client reply
    # @return [Object] The actual FHIR resource or bundle
    def extract_resource_from_reply(reply)
      return reply.resource if reply.is_a?(FHIR::ClientReply) || reply.respond_to?(:resource)
      reply
    end

    # Validate FHIR resource
    #
    # @param resource [FHIR resource] Resource to validate
    # @param expected_type [Class] Expected FHIR resource class
    # @return [Boolean] true if valid
    # @raise [FhirValidationError] if resource is invalid
    def validate_resource(resource, expected_type)
      # Check both FHIR::R4::* and FHIR::* class names
      resource_class_name = resource.class.name
      expected_base_name = expected_type.name.split('::').last
      actual_base_name = resource_class_name.split('::').last

      return true if resource.is_a?(expected_type)
      return true if actual_base_name == expected_base_name

      Rails.logger.warn("[FHIR] Invalid resource type. Expected #{expected_type}, got #{resource.class}")
      raise FhirValidationError, "Invalid FHIR resource type: expected #{expected_type}, got #{resource.class}"
    end

    # Extract resources from FHIR Bundle response
    #
    # @param response [FHIR::Bundle] Bundle response
    # @param resource_type [Class] Type of resources to extract
    # @return [Array] Array of resources
    def extract_resources(response, resource_type)
      return [] unless response.is_a?(FHIR::Bundle) || response.class.name.include?('Bundle')
      return [] unless response.entry.present?

      expected_base_name = resource_type.name.split('::').last
      response.entry.map(&:resource).compact.select do |r|
        r.is_a?(resource_type) || r.class.name.split('::').last == expected_base_name
      end
    end

  end
end
