class AuthController < ApplicationController
  before_action :redirect_if_logged_in, only: [:request_login]

  # Initiate LINE login request
  # Generates authorization URL with state and nonce for CSRF protection
  def request_login
    handler = LineLoginHandler.new
    auth_request = handler.create_authorization_request(callback_url)

    # Store state and nonce in session for verification in callback
    session[:line_login_state] = auth_request[:state]
    session[:line_login_nonce] = auth_request[:nonce]

    if request.format.json?
      render json: { authorization_url: auth_request[:authorization_url] }
    else
      redirect_to auth_request[:authorization_url], allow_other_host: true
    end
  end

  # Handle LINE OAuth callback
  # Exchanges authorization code for tokens and authenticates user
  def callback
    # Validate state parameter to prevent CSRF attacks
    state = params[:state]
    code = params[:code]

    unless state && session[:line_login_state] == state
      flash[:alert] = 'Invalid state parameter. Please try logging in again.'
      render status: :bad_request, json: { error: 'invalid_state' }
      return
    end

    unless code
      flash[:alert] = 'Missing authorization code. Please try logging in again.'
      render status: :bad_request, json: { error: 'missing_code' }
      return
    end

    begin
      # Complete the LOGIN flow
      handler = LineLoginHandler.new
      user = handler.handle_callback(code, callback_url, state, session[:line_login_nonce])

      # Log the user in
      login_user(user)

      # Clear session tokens
      session.delete(:line_login_state)
      session.delete(:line_login_nonce)

      flash[:notice] = "Welcome, #{user.name}!"
      redirect_to '/'
    rescue LineAuthService::AuthenticationError => e
      flash[:alert] = 'Failed to authenticate with LINE. Please try again.'
      Rails.logger.warn("LINE authentication error: #{e.message}")
      render status: :unauthorized, json: { error: 'authentication_failed' }
    rescue LineAuthService::NetworkError => e
      flash[:alert] = 'Network error connecting to LINE. Please try again.'
      Rails.logger.error("LINE network error: #{e.message}")
      render status: :service_unavailable, json: { error: 'network_error' }
    rescue StandardError => e
      flash[:alert] = 'An unexpected error occurred. Please try again.'
      Rails.logger.error("Unexpected error during LINE callback: #{e.message}")
      render status: :internal_server_error, json: { error: 'internal_error' }
    end
  end

  # Logout user
  def logout
    logout_user
    flash[:notice] = 'You have been logged out.'
    redirect_to '/'
  end

  private

  # Get the callback URL for this environment
  # @return [String] Full callback URL
  def callback_url
    line_callback_url
  end

  # Check if user is already logged in and redirect if so
  def redirect_if_logged_in
    redirect_to '/' if logged_in?
  end
end
