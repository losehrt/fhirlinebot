# FHIR Service Errors - Exception hierarchy for FHIR operations
module Fhir
  # Base error for all FHIR service exceptions
  class FhirServiceError < StandardError; end

  # Raised when FHIR resource is not found
  class FhirResourceNotFoundError < FhirServiceError; end

  # Raised when FHIR server returns 400+ status
  class FhirServerError < FhirServiceError; end

  # Raised when authentication fails
  class FhirAuthenticationError < FhirServiceError; end

  # Raised when operation is not allowed
  class FhirAuthorizationError < FhirServiceError; end

  # Raised when FHIR resource validation fails
  class FhirValidationError < FhirServiceError; end
end
