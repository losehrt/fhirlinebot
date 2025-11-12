class LineAuthService
  # Custom errors for LINE authentication
  class AuthenticationError < StandardError; end
  class NetworkError < StandardError; end

  BASE_URL = 'https://api.line.biz'
  TOKEN_ENDPOINT = "#{BASE_URL}/v2.0/token"
  PROFILE_ENDPOINT = 'https://api.line.me/v2/profile'
  AUTH_ENDPOINT = 'https://web.line.biz/web/login'

  def initialize(channel_id = nil, channel_secret = nil)
    @channel_id = channel_id || ENV['LINE_CHANNEL_ID']
    @channel_secret = channel_secret || ENV['LINE_CHANNEL_SECRET']
    validate_credentials!
  end

  # Exchange authorization code for access token
  # @param code [String] Authorization code from LINE login
  # @param redirect_uri [String] Redirect URI used in authorization request
  # @return [Hash] Token response containing access_token, refresh_token, expires_in
  # @raise [AuthenticationError] If code is invalid
  # @raise [NetworkError] If network error occurs
  def exchange_code!(code, redirect_uri)
    params = {
      grant_type: 'authorization_code',
      code: code,
      redirect_uri: redirect_uri,
      client_id: @channel_id,
      client_secret: @channel_secret
    }

    response = post_request(TOKEN_ENDPOINT, params)
    parse_token_response(response)
  rescue Errno::ECONNREFUSED, Timeout::Error, Net::OpenTimeout => e
    raise NetworkError, "Failed to exchange code: #{e.message}"
  rescue StandardError => e
    handle_api_error(e, 'Failed to exchange authorization code')
  end

  # Fetch user profile using access token
  # @param access_token [String] ACCESS token from LINE
  # @return [Hash] User profile containing userId, displayName, pictureUrl
  # @raise [AuthenticationError] If access token is invalid or expired
  # @raise [NetworkError] If network error occurs
  def fetch_profile!(access_token)
    headers = {
      'Authorization' => "Bearer #{access_token}",
      'Content-Type' => 'application/x-www-form-urlencoded'
    }

    response = get_request(PROFILE_ENDPOINT, headers)
    parse_profile_response(response)
  rescue OpenSSL::SSL::SSLError, Net::OpenTimeout => e
    raise NetworkError, "Failed to fetch profile: #{e.message}"
  rescue StandardError => e
    handle_api_error(e, 'Failed to fetch user profile')
  end

  # Refresh access token using refresh token
  # @param refresh_token [String] Refresh token from previous token response
  # @return [Hash] New token response with updated access_token and expires_in
  # @raise [AuthenticationError] If refresh token is invalid or expired
  # @raise [NetworkError] If network error occurs
  def refresh_token!(refresh_token)
    params = {
      grant_type: 'refresh_token',
      refresh_token: refresh_token,
      client_id: @channel_id,
      client_secret: @channel_secret
    }

    response = post_request(TOKEN_ENDPOINT, params)
    parse_token_response(response)
  rescue Errno::ECONNREFUSED, Timeout::Error, Net::OpenTimeout => e
    raise NetworkError, "Failed to refresh token: #{e.message}"
  rescue StandardError => e
    handle_api_error(e, 'Failed to refresh access token')
  end

  # Generate LINE authorization URL for user to visit
  # @param redirect_uri [String] Where to redirect after authorization
  # @param state [String] CSRF protection parameter
  # @param nonce [String] Nonce for ID token validation
  # @param scope [String] Requested scopes (default: 'profile openid')
  # @return [String] Authorization URL
  def get_authorization_url(redirect_uri, state, nonce, scope: 'profile openid')
    params = {
      client_id: @channel_id,
      redirect_uri: redirect_uri,
      response_type: 'code',
      scope: scope,
      state: state,
      nonce: nonce
    }

    "#{AUTH_ENDPOINT}?#{params.map { |k, v| "#{k}=#{CGI.escape(v.to_s)}" }.join('&')}"
  end

  private

  def validate_credentials!
    raise 'LINE_CHANNEL_ID not configured' if @channel_id.blank?
    raise 'LINE_CHANNEL_SECRET not configured' if @channel_secret.blank?
  end

  def post_request(url, params)
    response = HTTParty.post(
      url,
      body: params,
      headers: { 'Content-Type' => 'application/x-www-form-urlencoded' }
    )

    handle_response_status(response)
    response
  end

  def get_request(url, headers = {})
    response = HTTParty.get(url, headers: headers)
    handle_response_status(response)
    response
  end

  def handle_response_status(response)
    case response.code
    when 200..299
      # Success, do nothing
    when 400
      raise AuthenticationError, "Invalid request: #{response['error_description']}"
    when 401
      raise AuthenticationError, 'Unauthorized: Invalid token or credentials'
    when 403
      raise AuthenticationError, 'Forbidden: Access denied'
    when 400..499
      raise AuthenticationError, "Client error (#{response.code}): #{response['error_description']}"
    when 500..599
      raise NetworkError, "Server error (#{response.code})"
    else
      raise NetworkError, "Unexpected response code: #{response.code}"
    end
  end

  def parse_token_response(response)
    body = response.is_a?(String) ? JSON.parse(response) : response

    {
      access_token: body['access_token'],
      token_type: body['token_type'],
      expires_in: body['expires_in'],
      refresh_token: body['refresh_token'],
      scope: body['scope']
    }
  end

  def parse_profile_response(response)
    body = response.is_a?(String) ? JSON.parse(response) : response

    {
      userId: body['userId'],
      displayName: body['displayName'],
      pictureUrl: body['pictureUrl'],
      statusMessage: body['statusMessage']
    }
  end

  def handle_api_error(error, message)
    case error
    when AuthenticationError
      raise error
    when NetworkError
      raise error
    when JSON::ParserError
      raise NetworkError, "#{message}: Invalid JSON response"
    else
      raise NetworkError, "#{message}: #{error.message}"
    end
  end
end
