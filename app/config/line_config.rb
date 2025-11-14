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

    # Get LINE Channel Access Token for Messaging API
    # Priority: Credentials > ENV > Database (org-specific) > Database (global)
    #
    # @param organization_id [Integer, nil] Organization ID for multi-tenant support
    # @return [String, nil] Channel Access Token or nil if not configured
    def access_token(organization_id: nil)
      @config_cache ||= {}
      cache_key = "line_config_access_token_#{organization_id}"
      return @config_cache[cache_key] if @config_cache.key?(cache_key)

      # Priority 1: Rails Credentials
      cred_token = credentials_access_token
      if cred_token.present?
        return @config_cache[cache_key] = cred_token
      end

      # Priority 2: Environment variable (global default)
      if ENV['LINE_CHANNEL_ACCESS_TOKEN'].present?
        return @config_cache[cache_key] = ENV['LINE_CHANNEL_ACCESS_TOKEN']
      end

      # Priority 3: Database configuration (organization-specific or global)
      db_config = database_config(organization_id)
      if db_config&.access_token.present?
        return @config_cache[cache_key] = db_config.access_token
      end

      nil
    end

    # Get response mode for text message replies
    # Priority: ENV > Database (org-specific) > Database (global) > Default (:flex)
    #
    # @param organization_id [Integer, nil] Organization ID for multi-tenant support
    # @return [Symbol] Response mode (:flex, :text, etc.)
    def response_mode(organization_id: nil)
      @config_cache ||= {}
      cache_key = "line_config_response_mode_#{organization_id}"
      return @config_cache[cache_key] if @config_cache.key?(cache_key)

      # Priority 1: Environment variable
      if ENV['LINE_RESPONSE_MODE'].present?
        mode = ENV['LINE_RESPONSE_MODE'].downcase.to_sym
        return @config_cache[cache_key] = mode
      end

      # Priority 2: Database configuration (organization-specific or global)
      db_config = database_config(organization_id)
      if db_config&.response_mode.present?
        mode = db_config.response_mode.downcase.to_sym
        return @config_cache[cache_key] = mode
      end

      # Default: flex mode (sends both text and styled flex message)
      @config_cache[cache_key] = :flex
    end

    # Get LINE Messaging API Channel ID
    # This is separate from LINE Login channel_id as they are independent channels
    # Priority: Credentials > ENV > Database (org-specific) > Database (global)
    #
    # @param organization_id [Integer, nil] Organization ID for multi-tenant support
    # @return [String, nil] Messaging API Channel ID or nil if not configured
    def messaging_channel_id(organization_id: nil)
      @config_cache ||= {}
      cache_key = "line_config_messaging_channel_id_#{organization_id}"
      return @config_cache[cache_key] if @config_cache.key?(cache_key)

      # Priority 1: Rails Credentials (line.messaging.channel_id)
      cred_id = credentials_messaging_channel_id
      if cred_id.present?
        return @config_cache[cache_key] = cred_id
      end

      # Priority 2: Environment variable
      if ENV['LINE_MESSAGING_CHANNEL_ID'].present?
        return @config_cache[cache_key] = ENV['LINE_MESSAGING_CHANNEL_ID']
      end

      # Priority 3: Database configuration (fallback to channel_id if not specified)
      db_config = database_config(organization_id)
      if db_config&.access_token.present? && db_config.channel_id.present?
        return @config_cache[cache_key] = db_config.channel_id
      end

      nil
    end

    # Get LINE Messaging API Channel Secret
    # This is separate from LINE Login channel_secret as they are independent channels
    # Priority: Credentials > ENV > Database (org-specific) > Database (global)
    #
    # @param organization_id [Integer, nil] Organization ID for multi-tenant support
    # @return [String, nil] Messaging API Channel Secret or nil if not configured
    def messaging_channel_secret(organization_id: nil)
      @config_cache ||= {}
      cache_key = "line_config_messaging_channel_secret_#{organization_id}"
      return @config_cache[cache_key] if @config_cache.key?(cache_key)

      # Priority 1: Rails Credentials (line.messaging.channel_secret)
      cred_secret = credentials_messaging_channel_secret
      if cred_secret.present?
        return @config_cache[cache_key] = cred_secret
      end

      # Priority 2: Environment variable
      if ENV['LINE_MESSAGING_CHANNEL_SECRET'].present?
        return @config_cache[cache_key] = ENV['LINE_MESSAGING_CHANNEL_SECRET']
      end

      # Priority 3: Database configuration (fallback to channel_secret if not specified)
      db_config = database_config(organization_id)
      if db_config&.access_token.present? && db_config.channel_secret.present?
        return @config_cache[cache_key] = db_config.channel_secret
      end

      nil
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
    # Supports multiple credential structures:
    # - line_login.channel_id (LINE Login)
    # - line.login.channel_id (LINE Login with nested structure)
    # - line.channel_id (fallback)
    #
    # @return [String, nil] Channel ID from credentials or nil
    def credentials_channel_id
      return nil unless credentials_available?

      # Try different credential structures in order
      # 1. line.login.channel_id (preferred nested structure)
      result = Rails.application.credentials&.dig(:line, :login, :channel_id)
      # 2. line_login.channel_id (legacy structure)
      result ||= Rails.application.credentials&.dig(:line_login, :channel_id)
      # 3. line.channel_id (flat structure)
      result ||= Rails.application.credentials&.dig(:line, :channel_id)
      # 4. Support typo variant 'cahnnel_id' for backward compatibility
      result ||= Rails.application.credentials&.dig(:line, :cahnnel_id)
      result
    rescue => e
      Rails.logger.debug("Could not load LINE channel_id from credentials: #{e.message}")
      nil
    end

    # Get LINE Channel Secret from Rails credentials
    # Supports multiple credential structures:
    # - line_login.channel_secret (LINE Login)
    # - line.login.channel_secret (LINE Login with nested structure)
    # - line.channel_secret (fallback)
    #
    # @return [String, nil] Channel Secret from credentials or nil
    def credentials_channel_secret
      return nil unless credentials_available?

      # Try different credential structures in order
      # 1. line.login.channel_secret (preferred nested structure)
      result = Rails.application.credentials&.dig(:line, :login, :channel_secret)
      # 2. line_login.channel_secret (legacy structure)
      result ||= Rails.application.credentials&.dig(:line_login, :channel_secret)
      # 3. line.channel_secret (flat structure)
      result ||= Rails.application.credentials&.dig(:line, :channel_secret)
      result
    rescue => e
      Rails.logger.debug("Could not load LINE channel_secret from credentials: #{e.message}")
      nil
    end

    # Get LINE Channel Access Token from Rails credentials
    # Supports multiple credential structures:
    # - line.messaging.access_token (Messaging API with nested structure)
    # - line_login.access_token (legacy)
    # - line.access_token (fallback)
    #
    # @return [String, nil] Channel Access Token from credentials or nil
    def credentials_access_token
      return nil unless credentials_available?

      # Try different credential structures in order
      # 1. line.messaging.access_token (preferred nested structure for Messaging API)
      result = Rails.application.credentials&.dig(:line, :messaging, :access_token)
      # 2. line_login.access_token (legacy structure)
      result ||= Rails.application.credentials&.dig(:line_login, :access_token)
      # 3. line.access_token (flat structure)
      result ||= Rails.application.credentials&.dig(:line, :access_token)
      result
    rescue => e
      Rails.logger.debug("Could not load LINE access_token from credentials: #{e.message}")
      nil
    end

    # Get LINE Messaging API Channel ID from Rails credentials
    # Reads from line.messaging.channel_id structure
    #
    # @return [String, nil] Messaging API Channel ID from credentials or nil
    def credentials_messaging_channel_id
      return nil unless credentials_available?

      Rails.application.credentials&.dig(:line, :messaging, :channel_id)
    rescue => e
      Rails.logger.debug("Could not load LINE messaging channel_id from credentials: #{e.message}")
      nil
    end

    # Get LINE Messaging API Channel Secret from Rails credentials
    # Reads from line.messaging.channel_secret structure
    #
    # @return [String, nil] Messaging API Channel Secret from credentials or nil
    def credentials_messaging_channel_secret
      return nil unless credentials_available?

      Rails.application.credentials&.dig(:line, :messaging, :channel_secret)
    rescue => e
      Rails.logger.debug("Could not load LINE messaging channel_secret from credentials: #{e.message}")
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
