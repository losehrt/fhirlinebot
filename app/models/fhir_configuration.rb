# FhirConfiguration - Store FHIR server configuration per organization
# Allows each organization to have its own FHIR server connection

class FhirConfiguration < ApplicationRecord
  belongs_to :organization

  # Validations
  validates :server_url, presence: true, format: { with: %r{\Ahttps?://}, message: 'must be a valid HTTP(S) URL' }
  validates :organization_id, presence: true

  # Scopes
  scope :active, -> { where(is_active: true) }

  # Class methods
  class << self
    # Find active configuration for an organization
    #
    # @param organization_id [Integer] Organization ID
    # @return [FhirConfiguration, nil] Active configuration or nil
    def for_organization(organization_id)
      return nil unless organization_id.present?

      active.find_by(organization_id: organization_id)
    end
  end

  # Instance methods

  # Test connection to FHIR server
  #
  # @return [Boolean] true if connection successful
  def validate_connection!
    client = FHIR::Client.new(server_url)
    # Try to access the FHIR capabilities endpoint
    response = client.client.get('metadata')

    if response.code.to_i == 200
      update!(last_validated_at: Time.current)
      true
    else
      false
    end
  rescue StandardError => e
    Rails.logger.error("FHIR connection validation failed for #{server_url}: #{e.message}")
    false
  end
end
