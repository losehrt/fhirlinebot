# FHIR Service Errors - Exception hierarchy for FHIR operations
module Fhir
  # Module to hold all error classes
  module Errors
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

  # Expose errors at module level for backward compatibility
  FhirServiceError = Errors::FhirServiceError
  FhirResourceNotFoundError = Errors::FhirResourceNotFoundError
  FhirServerError = Errors::FhirServerError
  FhirAuthenticationError = Errors::FhirAuthenticationError
  FhirAuthorizationError = Errors::FhirAuthorizationError
  FhirValidationError = Errors::FhirValidationError
end
