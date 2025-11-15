# FhirPatientService - Service for FHIR patient operations
# Provides higher-level operations like fetching random patients

class FhirPatientService
  def initialize(organization_id: nil)
    @service = Fhir::ClientService.new(organization_id: organization_id)
  end

  # Fetch a random patient from FHIR server
  #
  # @param complete_data [Boolean] If true, only return patients with complete data
  #                                (name, gender, birthDate). Otherwise just requires name.
  # @return [FHIR::R4::Patient, nil] Random patient or nil if not found
  # @raise [Fhir::FhirServiceError] on FHIR service errors
  MAX_RETRIES = 10
  SEARCH_BATCH_SIZE = 500

  def get_random_patient(complete_data: false)
    request_id = SecureRandom.hex(8)
    data_type = complete_data ? 'complete data' : 'name'

    Rails.logger.info("[FhirPatientService][#{request_id}] Fetching random patient with #{data_type}")

    begin
      # Use unified search logic
      patient = search_and_select_patient(
        request_id: request_id,
        complete_data: complete_data
      )

      if patient
        Rails.logger.info("[FhirPatientService][#{request_id}] Got patient: #{patient.id}")
        return patient
      end

      nil
    rescue Fhir::FhirServiceError => e
      Rails.logger.error("[FhirPatientService][#{request_id}] FHIR error: #{e.message}")
      raise
    rescue StandardError => e
      Rails.logger.error("[FhirPatientService][#{request_id}] Error: #{e.message}")
      raise Fhir::FhirServiceError, "Failed to fetch random patient: #{e.message}"
    end
  end

  private

  # Unified search and select logic for both regular and complete data patients
  #
  # @param request_id [String] Request ID for logging
  # @param complete_data [Boolean] Whether to filter for complete data
  # @param attempt [Integer] Current retry attempt
  # @return [FHIR::R4::Patient, nil] Random patient or nil
  def search_and_select_patient(request_id:, complete_data:, attempt: 0)
    return nil if attempt >= MAX_RETRIES

    if attempt > 0
      Rails.logger.info("[FhirPatientService][#{request_id}] Retry attempt #{attempt}/#{MAX_RETRIES}")
    end

    # Search for patients
    search_params = { _count: SEARCH_BATCH_SIZE }
    Rails.logger.debug("[FhirPatientService][#{request_id}] Searching with params: #{search_params}")

    patients = @service.search_patients(search_params)
    Rails.logger.info("[FhirPatientService][#{request_id}] Found #{patients.length} total patients")
    return nil if patients.empty?

    # Filter patients based on criteria
    if complete_data
      filtered_patients = patients.select { |p| has_complete_data?(p) }
      Rails.logger.info("[FhirPatientService][#{request_id}] Filtered to #{filtered_patients.length} patients with complete data")
    else
      filtered_patients = patients.select { |p| has_valid_name?(p) }
      Rails.logger.info("[FhirPatientService][#{request_id}] Filtered to #{filtered_patients.length} patients with names")
    end

    # Return random patient if found
    return filtered_patients.sample if filtered_patients.any?

    # Retry if no patients found
    Rails.logger.warn("[FhirPatientService][#{request_id}] No matching patients found, retrying...")
    search_and_select_patient(request_id: request_id, complete_data: complete_data, attempt: attempt + 1)
  end

  # Check if patient has a valid name
  #
  # @param patient [FHIR::R4::Patient] Patient to check
  # @return [Boolean] true if patient has valid name
  def has_valid_name?(patient)
    patient.name.present? && patient.name.any? do |n|
      (n.family.present? || n.given.present?) &&
      (n.family.to_s.strip != '' || n.given&.any? { |g| g.to_s.strip != '' })
    end
  end

  # Check if patient has complete data
  #
  # @param patient [FHIR::R4::Patient] Patient to check
  # @return [Boolean] true if patient has name, gender, and birthDate
  def has_complete_data?(patient)
    has_name = has_valid_name?(patient)
    has_gender = patient.gender.present? && patient.gender.to_s.strip != ''
    has_birth_date = patient.birthDate.present?

    has_name && has_gender && has_birth_date
  end

  # Format patient data for display
  #
  # @param patient [FHIR::R4::Patient] Patient resource
  # @return [Hash] Formatted patient information
  public

  def format_patient_data(patient)
    {
      id: patient.id,
      name: format_name(patient.name),
      gender: format_gender(patient.gender),
      birth_date: patient.birthDate,
      phone: format_phone(patient.telecom),
      address: format_address(patient.address),
      identifiers: format_identifiers(patient.identifier)
    }
  end

  private

  # Format patient name
  #
  # @param name_array [Array] Array of FHIR HumanName objects
  # @return [String] Formatted name
  def format_name(name_array)
    return '未提供' if name_array.blank?

    names = name_array.map do |n|
      parts = []
      parts << n.family if n.family.present?
      parts << n.given&.join(' ') if n.given.present?
      parts.join(' ')
    end.compact

    names.any? ? names.first : '未提供'
  end

  # Format gender code to Chinese
  #
  # @param gender [String] Gender code (male, female, other, unknown)
  # @return [String] Chinese gender description
  def format_gender(gender)
    case gender
    when 'male'
      '男性'
    when 'female'
      '女性'
    when 'other'
      '其他'
    when 'unknown'
      '未知'
    else
      gender.present? ? gender : '未提供'
    end
  end

  # Format phone number
  #
  # @param telecom_array [Array] Array of FHIR ContactPoint objects
  # @return [String] Phone number or "未提供"
  def format_phone(telecom_array)
    return '未提供' if telecom_array.blank?

    phones = telecom_array.select { |t| t.system == 'phone' }.map(&:value)
    phones.any? ? phones.first : '未提供'
  end

  # Format address
  #
  # @param address_array [Array] Array of FHIR Address objects
  # @return [String] Formatted address
  def format_address(address_array)
    return '未提供' if address_array.blank?

    address = address_array.first
    return '未提供' if address.blank?

    parts = []
    parts << address.country if address.country.present?
    parts << address.state if address.state.present?
    parts << address.city if address.city.present?
    parts << address.district if address.district.present?

    parts.any? ? parts.join(' ') : '未提供'
  end

  # Format identifiers
  #
  # @param identifier_array [Array] Array of FHIR Identifier objects
  # @return [Array<Hash>] Array of identifier hashes
  def format_identifiers(identifier_array)
    return [] if identifier_array.blank?

    identifier_array.map do |id|
      {
        type: id.type&.text || id.type&.coding&.first&.code || '未知',
        value: id.value
      }
    end
  end
end
