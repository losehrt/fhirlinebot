class ApplicationSetting < ApplicationRecord
  # Ensure only one settings record exists
  validates :id, uniqueness: true, if: -> { persisted? }
  validates :line_channel_id, :line_channel_secret, presence: true, if: :configured?

  # Encrypt sensitive data (Rails 7.0+ encrypted attributes)
  # Note: If encrypt is not available, secrets are still stored in database
  # For production, use Rails encrypted credentials or a secrets manager
  begin
    encrypt :line_channel_secret, deterministic: false
  rescue NoMethodError
    # Rails version doesn't support encrypt, will store as-is
    # Consider using Rails.application.credentials for sensitive data in production
  end

  # Scopes
  scope :current, -> { first || create! }

  # Check if LINE credentials are configured
  def self.configured?
    setting = current
    setting.configured? && setting.line_channel_id.present? && setting.line_channel_secret.present?
  end

  # Validate LINE credentials by testing the API connection
  def validate_line_credentials!
    return false if line_channel_id.blank? || line_channel_secret.blank?

    begin
      validator = LineValidator.new(line_channel_id, line_channel_secret)
      result = validator.validate!

      if result
        update(
          configured: true,
          last_validated_at: Time.current,
          validation_error: nil
        )
        true
      else
        update(validation_error: 'Invalid LINE credentials')
        false
      end
    rescue StandardError => e
      update(validation_error: "Validation error: #{e.message}")
      false
    end
  end

  # Get current settings or create default
  def self.current
    first || create!
  end

  # Clear configuration
  def clear_configuration!
    update(
      configured: false,
      line_channel_id: nil,
      line_channel_secret: nil,
      validation_error: nil
    )
  end
end
