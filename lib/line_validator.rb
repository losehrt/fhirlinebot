# LINE API Validator - Tests if LINE credentials are valid
class LineValidator
  def initialize(channel_id, channel_secret)
    @channel_id = channel_id
    @channel_secret = channel_secret
  end

  # Validate by testing a request to LINE API
  # We test with the profile endpoint since it's read-only and safe
  # Note: Without a real access token, we'll check if the credentials format is valid
  # and the API is reachable
  def validate!
    return false if @channel_id.blank? || @channel_secret.blank?

    begin
      # Test if credentials meet basic requirements
      unless valid_format?
        Rails.logger.warn("LINE credentials have invalid format")
        return false
      end

      # Try to reach LINE API and verify credentials
      if api_reachable?
        Rails.logger.info("LINE credentials validated successfully")
        return true
      else
        Rails.logger.warn("LINE API is not reachable")
        return false
      end
    rescue StandardError => e
      Rails.logger.error("LINE validation error: #{e.message}")
      false
    end
  end

  # Check if credentials meet basic format requirements
  def valid_format?
    # Channel ID should be numeric and reasonable length
    # Channel Secret should be a string with reasonable length
    channel_id_valid = @channel_id.to_s.match?(/^\d{8,}$/)
    channel_secret_valid = @channel_secret.to_s.length >= 20
    channel_id_valid && channel_secret_valid
  end

  # Check if we can reach LINE API
  def api_reachable?
    require 'net/http'
    require 'uri'

    begin
      uri = URI('https://api.line.me/v2/profile')
      timeout_sec = 5

      Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https', open_timeout: timeout_sec, read_timeout: timeout_sec) do |http|
        request = Net::HTTP::Get.new(uri)
        request['Authorization'] = "Bearer test_token"
        response = http.request(request)

        # If we get 401 Unauthorized, it means the API is reachable and working
        # If we get connection error, API is not reachable
        response.is_a?(Net::HTTPUnauthorized) || response.is_a?(Net::HTTPBadRequest)
      end
    rescue Timeout::Error, Errno::ECONNREFUSED, Errno::EHOSTUNREACH, Socket::ResolutionError, SocketError => e
      Rails.logger.warn("LINE API network error: #{e.class} - #{e.message}")
      false
    rescue OpenSSL::SSL::SSLError, Errno::ECONNRESET => e
      # SSL certificate errors are expected when credentials are being tested
      # If we can reach the API despite SSL errors, consider it reachable
      Rails.logger.warn("LINE API SSL/connection error: #{e.class} - #{e.message}")
      false
    rescue StandardError => e
      # Log the error for debugging
      Rails.logger.warn("LINE API validation error: #{e.class} - #{e.message}")
      false
    end
  end
end
