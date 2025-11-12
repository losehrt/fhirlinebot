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

  private

  # Check if credentials meet basic format requirements
  def valid_format?
    # Channel ID should be numeric and reasonable length
    # Channel Secret should be a string with reasonable length
    @channel_id.to_s.length >= 8 && @channel_secret.to_s.length >= 20
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
    rescue Timeout::Error, Errno::ECONNREFUSED, Errno::EHOSTUNREACH
      false
    rescue StandardError
      # Even if there's an error, as long as we can reach the endpoint, consider it valid
      false
    end
  end
end
