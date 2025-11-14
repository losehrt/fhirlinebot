# LineConfig - Centralized configuration for LINE Login
# Supports multiple sources with priority: ENV > DB > Defaults
#
# Usage:
#   LineConfig.channel_id      # Get Channel ID
#   LineConfig.channel_secret  # Get Channel Secret
#   LineConfig.redirect_uri    # Get Redirect URI
#   LineConfig.configured?     # Check if properly configured

class LineConfig
  class << self
    # Get LINE Channel ID
    # Priority: ENV > Database > Raise error
    #
    # @return [String] Channel ID
    # @raise [StandardError] if no Channel ID configured
    def channel_id
      return @channel_id if defined?(@channel_id) && @channel_id

      @channel_id = ENV['LINE_LOGIN_CHANNEL_ID'] || database_channel_id
      raise 'LINE_LOGIN_CHANNEL_ID not configured' if @channel_id.blank?

      @channel_id
    end

    # Get LINE Channel Secret
    # Priority: ENV > Database > Raise error
    #
    # @return [String] Channel Secret
    # @raise [StandardError] if no Channel Secret configured
    def channel_secret
      return @channel_secret if defined?(@channel_secret) && @channel_secret

      @channel_secret = ENV['LINE_LOGIN_CHANNEL_SECRET'] || database_channel_secret
      raise 'LINE_LOGIN_CHANNEL_SECRET not configured' if @channel_secret.blank?

      @channel_secret
    end

    # Get LINE Login Redirect URI
    # Priority: ENV > Rails config > Default
    #
    # @return [String] Redirect URI
    def redirect_uri
      ENV['LINE_LOGIN_REDIRECT_URI'] ||
        Rails.application.config.line_login_redirect_uri ||
        default_redirect_uri
    end

    # Get all configuration as a hash
    #
    # @return [Hash] Configuration hash with :channel_id, :channel_secret, :redirect_uri
    def config
      {
        channel_id: channel_id,
        channel_secret: channel_secret,
        redirect_uri: redirect_uri
      }
    rescue StandardError => e
      Rails.logger.warn("LineConfig error: #{e.message}")
      raise
    end

    # Check if LINE is properly configured
    #
    # @return [Boolean] true if Channel ID and Secret are configured
    def configured?
      channel_id.present? && channel_secret.present?
    rescue StandardError
      false
    end

    # Clear cached configuration
    # Call after updating configuration in database
    #
    # @return [void]
    def refresh!
      @channel_id = nil
      @channel_secret = nil
      Rails.cache.delete('line_config_cache') if Rails.cache.respond_to?(:delete)
      Rails.logger.info 'LineConfig cache cleared'
    end

    private

    # Get Channel ID from database
    #
    # @return [String, nil] Channel ID or nil if not configured
    def database_channel_id
      return nil unless table_exists?

      setting = ApplicationSetting.current
      setting&.line_channel_id
    rescue => e
      Rails.logger.debug("Could not load Channel ID from database: #{e.message}")
      nil
    end

    # Get Channel Secret from database
    #
    # @return [String, nil] Channel Secret or nil if not configured
    def database_channel_secret
      return nil unless table_exists?

      setting = ApplicationSetting.current
      setting&.line_channel_secret
    rescue => e
      Rails.logger.debug("Could not load Channel Secret from database: #{e.message}")
      nil
    end

    # Check if application_settings table exists in database
    #
    # @return [Boolean] true if table exists and is accessible
    def table_exists?
      return false unless ActiveRecord::Base.connection.data_source_exists?('application_settings')

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
end
