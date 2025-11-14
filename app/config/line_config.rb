# LineConfig - Centralized configuration for LINE Login
# Supports multiple sources with priority: Credentials > ENV > DB > Defaults
# Now with multi-tenant support via organization_id parameter
#
# Usage:
#   LineConfig.channel_id                        # Get default Channel ID
#   LineConfig.channel_id(organization_id: 1)    # Get organization-specific Channel ID
#   LineConfig.channel_secret                    # Get Channel Secret
#   LineConfig.channel_secret(organization_id: 1) # Get organization-specific Channel Secret
#   LineConfig.redirect_uri                      # Get Redirect URI
#   LineConfig.configured?                       # Check if properly configured

class LineConfig
  class << self
    # Get LINE Channel ID
    # Priority: Credentials > ENV > Database (org-specific) > Database (global) > Raise error
    #
    # @param organization_id [Integer, nil] Organization ID for multi-tenant support
    # @return [String] Channel ID
    # @raise [StandardError] if no Channel ID configured
    def channel_id(organization_id: nil)
      @config_cache ||= {}
      cache_key = "line_config_channel_id_#{organization_id}"
      return @config_cache[cache_key] if @config_cache.key?(cache_key)

      # Priority 1: Rails Credentials
      cred_id = credentials_channel_id
      if cred_id.present?
        return @config_cache[cache_key] = cred_id
      end

      # Priority 2: Environment variable (global default)
      if ENV['LINE_LOGIN_CHANNEL_ID'].present?
        return @config_cache[cache_key] = ENV['LINE_LOGIN_CHANNEL_ID']
      end

      # Priority 3: Database configuration (organization-specific or global)
      db_config = database_config(organization_id)
      if db_config&.channel_id.present?
        return @config_cache[cache_key] = db_config.channel_id
      end

      raise "LINE_LOGIN_CHANNEL_ID not configured for #{organization_id ? "organization #{organization_id}" : 'global'}"
    end

    # Get LINE Channel Secret
    # Priority: Credentials > ENV > Database (org-specific) > Database (global) > Raise error
    #
    # @param organization_id [Integer, nil] Organization ID for multi-tenant support
    # @return [String] Channel Secret
    # @raise [StandardError] if no Channel Secret configured
    def channel_secret(organization_id: nil)
      @config_cache ||= {}
      cache_key = "line_config_channel_secret_#{organization_id}"
      return @config_cache[cache_key] if @config_cache.key?(cache_key)

      # Priority 1: Rails Credentials
      cred_secret = credentials_channel_secret
      if cred_secret.present?
        return @config_cache[cache_key] = cred_secret
      end

      # Priority 2: Environment variable (global default)
      if ENV['LINE_LOGIN_CHANNEL_SECRET'].present?
        return @config_cache[cache_key] = ENV['LINE_LOGIN_CHANNEL_SECRET']
      end

      # Priority 3: Database configuration (organization-specific or global)
      db_config = database_config(organization_id)
      if db_config&.channel_secret.present?
        return @config_cache[cache_key] = db_config.channel_secret
      end

      raise "LINE_LOGIN_CHANNEL_SECRET not configured for #{organization_id ? "organization #{organization_id}" : 'global'}"
    end

    # Get LINE Login Redirect URI
    # Priority: ENV > Rails config > Default
    #
    # @param organization_id [Integer, nil] Organization ID (for consistency, not used for redirect)
    # @return [String] Redirect URI
    def redirect_uri(organization_id: nil)
      ENV['LINE_LOGIN_REDIRECT_URI'] ||
        (Rails.application.config.respond_to?(:line_login_redirect_uri) && Rails.application.config.line_login_redirect_uri) ||
        default_redirect_uri
    end

    # Get all configuration as a hash
    #
    # @param organization_id [Integer, nil] Organization ID for multi-tenant support
    # @return [Hash] Configuration hash with :channel_id, :channel_secret, :redirect_uri
    def config(organization_id: nil)
      {
        channel_id: channel_id(organization_id: organization_id),
        channel_secret: channel_secret(organization_id: organization_id),
        redirect_uri: redirect_uri(organization_id: organization_id)
      }
    rescue StandardError => e
      Rails.logger.warn("LineConfig error: #{e.message}")
      raise
    end

    # Check if LINE is properly configured
    #
    # @param organization_id [Integer, nil] Organization ID for multi-tenant support
    # @return [Boolean] true if Channel ID and Secret are configured
    def configured?(organization_id: nil)
      channel_id(organization_id: organization_id).present? &&
        channel_secret(organization_id: organization_id).present?
    rescue StandardError
      false
    end

    # Clear cached configuration
    # Call after updating configuration in database
    #
    # @return [void]
    def refresh!
      @config_cache = {}
      Rails.cache.delete('line_config_cache') if Rails.cache.respond_to?(:delete)
      Rails.logger.info 'LineConfig cache cleared'
    end

    private

    # Get LINE Channel ID from Rails credentials
    # Supports both 'line_login' and 'line' keys for compatibility
    # Only reads if credentials are fully loaded and available
    #
    # @return [String, nil] Channel ID from credentials or nil
    def credentials_channel_id
      return nil unless credentials_available?

      # Try 'line_login' first, then fallback to 'line'
      result = Rails.application.credentials&.dig(:line_login, :channel_id)
      result ||= Rails.application.credentials&.dig(:line, :channel_id)
      # Support typo variant 'cahnnel_id' for backward compatibility
      result ||= Rails.application.credentials&.dig(:line, :cahnnel_id)
      result
    rescue => e
      Rails.logger.debug("Could not load LINE channel_id from credentials: #{e.message}")
      nil
    end

    # Get LINE Channel Secret from Rails credentials
    # Supports both 'line_login' and 'line' keys for compatibility
    # Only reads if credentials are fully loaded and available
    #
    # @return [String, nil] Channel Secret from credentials or nil
    def credentials_channel_secret
      return nil unless credentials_available?

      # Try 'line_login' first, then fallback to 'line'
      result = Rails.application.credentials&.dig(:line_login, :channel_secret)
      result ||= Rails.application.credentials&.dig(:line, :channel_secret)
      result
    rescue => e
      Rails.logger.debug("Could not load LINE channel_secret from credentials: #{e.message}")
      nil
    end

    # Check if Rails credentials are available
    #
    # @return [Boolean] true if credentials are available
    def credentials_available?
      Rails.application.respond_to?(:credentials) && Rails.application.credentials.present?
    rescue => e
      Rails.logger.debug("Credentials not available: #{e.message}")
      false
    end

    # Get configuration from database
    # Supports both organization-specific and global defaults
    #
    # @param organization_id [Integer, nil] Organization ID
    # @return [LineConfiguration, nil] Configuration object or nil
    def database_config(organization_id = nil)
      return nil unless table_exists?

      LineConfiguration.for_organization(organization_id)
    rescue => e
      Rails.logger.debug("Could not load configuration from database: #{e.message}")
      nil
    end

    # Check if line_configurations table exists in database
    #
    # @return [Boolean] true if table exists and is accessible
    def table_exists?
      return false unless ActiveRecord::Base.connection.data_source_exists?('line_configurations')

      true
    rescue => e
      Rails.logger.debug("Database not ready: #{e.message}")
      false
    end

    # Default redirect URI for current environment
    #
    # @return [String] Redirect URI
    def default_redirect_uri
      app_url = ENV['APP_URL'] || Rails.application.config.action_mailer.default_url_options[:host] || 'localhost:3000'
      "#{app_url}/auth/line/callback"
    end
  end

  # Initialize config cache
  @config_cache = {}
end
