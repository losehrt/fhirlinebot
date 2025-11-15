# FhirPatientService - Service for FHIR patient operations
# Provides higher-level operations like fetching random patients

class FhirPatientService
  def initialize(organization_id: nil)
    @service = Fhir::ClientService.new(organization_id: organization_id)
  end

  # Fetch a random patient from FHIR server with a name
  #
  # Ensures the returned patient has a valid name value.
  # If a random patient doesn't have a name, will retry up to MAX_RETRIES times.
  #
  # @return [FHIR::R4::Patient, nil] Random patient with name or nil if not found
  # @raise [Fhir::FhirServiceError] on FHIR service errors
  MAX_RETRIES = 10

  def get_random_patient
    Rails.logger.info('[FhirPatientService] Fetching random patient with name')

    patients = @service.search_patients({})
    return nil if patients.empty?

    # Filter patients that have a name
    patients_with_name = patients.select { |p| has_valid_name?(p) }

    if patients_with_name.empty?
      Rails.logger.warn('[FhirPatientService] No patients with name found in first batch, retrying')
      # If no patients with name found, try again (retry logic)
      return retry_get_random_patient(patients_with_name)
    end

    random_patient = patients_with_name.sample
    Rails.logger.info("[FhirPatientService] Got random patient with name: #{random_patient.id}")
    random_patient
  rescue Fhir::FhirServiceError => e
    Rails.logger.error("[FhirPatientService] FHIR error: #{e.message}")
    raise
  rescue StandardError => e
    Rails.logger.error("[FhirPatientService] Error fetching random patient: #{e.message}")
    raise Fhir::FhirServiceError, "Failed to fetch random patient: #{e.message}"
  end

  def has_valid_name?(patient)
    patient.name.present? && patient.name.any? do |n|
      (n.family.present? || n.given.present?) &&
      (n.family.to_s.strip != '' || n.given&.any? { |g| g.to_s.strip != '' })
    end
  end

  def retry_get_random_patient(patients_with_name, attempt = 0)
    return nil if attempt >= MAX_RETRIES

    Rails.logger.info("[FhirPatientService] Retry attempt #{attempt + 1}/#{MAX_RETRIES}")
    patients = @service.search_patients({})
    return nil if patients.empty?

    patients_with_name = patients.select { |p| has_valid_name?(p) }

    if patients_with_name.any?
      random_patient = patients_with_name.sample
      Rails.logger.info("[FhirPatientService] Got random patient with name on retry #{attempt + 1}: #{random_patient.id}")
      return random_patient
    end

      # Recursively retry
    retry_get_random_patient(patients_with_name, attempt + 1)
  end

  # Format patient data for display
  #
  # @param patient [FHIR::R4::Patient] Patient resource
  # @return [Hash] Formatted patient information
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

  # Helper methods - private
  private

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

  def format_phone(telecom_array)
    return '未提供' if telecom_array.blank?

    phones = telecom_array.select { |t| t.system == 'phone' }.map(&:value)
    phones.any? ? phones.first : '未提供'
  end

  def format_address(address_array)
    return '未提供' if address_array.blank?

    address = address_array.first
    return '未提供' if address.blank?

    parts = []
    parts << address.country if address.country.present?
    parts << address.state if address.state.present?
    parts << address.city if address.city.present?
    parts << address.district if address.district.present?

    parts.any? ? parts.join(' ' ) : '未提供'
  end

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
