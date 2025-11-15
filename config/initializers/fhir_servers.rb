# FhirServerRegistry - Configuration for multiple FHIR servers
#
# Manages available FHIR servers and provides utilities for server selection
#
# Usage:
#   FhirServerRegistry.url_for('sandbox')  # Get sandbox server URL
#   FhirServerRegistry.all_servers          # Get all configured servers
#   FhirServerRegistry.default_server       # Get default server alias

class FhirServerRegistry
  SERVERS = {
    'sandbox' => {
      url: 'https://emr-smart.appx.com.tw/v/r4/fhir',
      name: '台灣 SMART Sandbox',
      description: '台灣智慧醫療 SMART on FHIR 官方沙箱環境',
      oauth2_enabled: true
    },
    'hapi' => {
      url: 'https://hapi.fhir.tw/fhir',
      name: 'HAPI FHIR',
      description: '台灣 HAPI FHIR 服務器',
      oauth2_enabled: false
    },
    'local' => {
      url: 'http://localhost:8080/fhir',
      name: '本地開發',
      description: '本地開發 FHIR 服務器',
      oauth2_enabled: false
    }
  }.freeze

  DEFAULT_SERVER = 'sandbox'.freeze

  class << self
    # Get FHIR server URL by alias
    #
    # @param alias_name [String, nil] Server alias (sandbox, hapi, local)
    #                                 If nil, uses default server
    # @return [String] FHIR server URL
    # @raise [ArgumentError] if alias_name is invalid
    def url_for(alias_name = nil)
      normalized = alias_name&.downcase&.strip
      normalized = DEFAULT_SERVER if normalized.nil? || normalized.empty?

      server_config = SERVERS[normalized]

      raise ArgumentError, "未知的 FHIR 伺服器別名: #{alias_name}" unless server_config

      server_config[:url]
    end

    # Get server information
    #
    # @param alias_name [String, nil] Server alias
    # @return [Hash] Server configuration hash
    def server_info(alias_name = nil)
      alias_name = alias_name&.downcase&.strip || DEFAULT_SERVER
      server_config = SERVERS[alias_name]

      raise ArgumentError, "未知的 FHIR 伺服器別名: #{alias_name}" unless server_config

      {
        alias: alias_name,
        name: server_config[:name],
        description: server_config[:description],
        url: server_config[:url],
        oauth2_enabled: server_config[:oauth2_enabled]
      }
    end

    # Get all available servers
    #
    # @return [Hash] Hash of all server configurations
    def all_servers
      SERVERS.transform_keys(&:dup).transform_values(&:dup)
    end

    # Get list of server aliases
    #
    # @return [Array<String>] List of available server aliases
    def aliases
      SERVERS.keys
    end

    # Get default server alias
    #
    # @return [String] Default server alias
    def default_server
      DEFAULT_SERVER
    end

    # Get default server URL
    #
    # @return [String] Default server URL
    def default_url
      url_for(DEFAULT_SERVER)
    end

    # Check if server alias is valid
    #
    # @param alias_name [String, nil] Server alias to check
    # @return [Boolean] true if alias is valid
    def valid_alias?(alias_name)
      normalized = alias_name&.downcase&.strip
      return true if normalized.nil? || normalized.empty?  # defaults to 'sandbox'

      SERVERS.key?(normalized)
    end

    # Validate and normalize server alias
    #
    # @param alias_name [String, nil] Server alias
    # @return [String] Normalized alias (lowercase, trimmed)
    # @raise [ArgumentError] if alias is invalid
    def normalize_alias(alias_name)
      normalized = alias_name&.downcase&.strip || DEFAULT_SERVER

      raise ArgumentError, "未知的 FHIR 伺服器別名: #{alias_name}" unless valid_alias?(normalized)

      normalized
    end
  end
end
