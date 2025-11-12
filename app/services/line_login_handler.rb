class LineLoginHandler
  def initialize(channel_id = nil, channel_secret = nil)
    @channel_id = channel_id || ENV['LINE_LOGIN_CHANNEL_ID']
    @channel_secret = channel_secret || ENV['LINE_LOGIN_CHANNEL_SECRET']
    @auth_service = LineAuthService.new(@channel_id, @channel_secret)
    validate_credentials!
  end

  # Handle the complete LINE login callback flow
  # @param code [String] Authorization code from LINE
  # @param redirect_uri [String] Redirect URI used in authorization request
  # @param state [String] State parameter for CSRF validation (optional)
  # @param nonce [String] Nonce for ID token validation (optional)
  # @return [User] The authenticated user
  # @raise [LineAuthService::AuthenticationError] If authentication fails
  # @raise [LineAuthService::NetworkError] If network error occurs
  def handle_callback(code, redirect_uri, state = nil, nonce = nil)
    # Step 1: Exchange authorization code for tokens
    token_response = @auth_service.exchange_code!(code, redirect_uri)
    access_token = token_response[:access_token]
    refresh_token = token_response[:refresh_token]
    expires_in = token_response[:expires_in]

    # Step 2: Fetch user profile using access token
    profile = @auth_service.fetch_profile!(access_token)
    line_user_id = profile[:userId]

    # Step 3: Create or update user with LINE account
    line_data = {
      userId: line_user_id,
      displayName: profile[:displayName],
      pictureUrl: profile[:pictureUrl],
      accessToken: access_token,
      refreshToken: refresh_token,
      expiresIn: expires_in
    }

    User.find_or_create_from_line(line_user_id, line_data)
  end

  # Create an authorization request with state and nonce for CSRF/token protection
  # @param redirect_uri [String] Where to redirect after authorization
  # @return [Hash] Authorization request with state, nonce, and authorization_url
  def create_authorization_request(redirect_uri)
    state = generate_secure_token
    nonce = generate_secure_token

    authorization_url = @auth_service.get_authorization_url(redirect_uri, state, nonce)

    {
      state: state,
      nonce: nonce,
      authorization_url: authorization_url
    }
  end

  private

  def validate_credentials!
    raise 'LINE_CHANNEL_ID not configured' if @channel_id.blank?
    raise 'LINE_CHANNEL_SECRET not configured' if @channel_secret.blank?
  end

  # Generate a secure random token for state/nonce
  # @return [String] 32-character hex string
  def generate_secure_token
    SecureRandom.hex(16)
  end
end
