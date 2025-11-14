require 'rails_helper'

describe 'Auth Login Page', type: :request do
  around(:each) do |example|
    # Temporarily set environment variables for this test
    old_channel_id = ENV['LINE_LOGIN_CHANNEL_ID']
    old_channel_secret = ENV['LINE_LOGIN_CHANNEL_SECRET']
    old_redirect_uri = ENV['LINE_LOGIN_REDIRECT_URI']

    ENV['LINE_LOGIN_CHANNEL_ID'] = 'test_channel_id'
    ENV['LINE_LOGIN_CHANNEL_SECRET'] = 'test_channel_secret'
    ENV['LINE_LOGIN_REDIRECT_URI'] = 'http://localhost:3000/auth/line/callback'

    example.run

    ENV['LINE_LOGIN_CHANNEL_ID'] = old_channel_id
    ENV['LINE_LOGIN_CHANNEL_SECRET'] = old_channel_secret
    ENV['LINE_LOGIN_REDIRECT_URI'] = old_redirect_uri
  end

  let(:line_channel_id) { 'test_channel_id' }
  let(:line_channel_secret) { 'test_channel_secret' }

  before do
    # Mock LineAuthService and LineLoginHandler to bypass environment variable validation
    allow_any_instance_of(LineAuthService).to receive(:validate_credentials!).and_return(true)
    allow_any_instance_of(LineLoginHandler).to receive(:validate_credentials!).and_return(true)
  end

  describe 'GET /auth/login' do
    it 'returns a successful response' do
      get auth_login_path
      expect(response).to have_http_status(:ok)
    end

    it 'renders the login template' do
      get auth_login_path
      expect(response).to render_template('auth/login')
    end

    it 'displays login page title' do
      get auth_login_path
      expect(response.body).to include('LINE Login')
    end

    it 'has a LINE login button' do
      get auth_login_path
      expect(response.body).to include('Line Login')
    end

    it 'redirects to dashboard if user is already logged in' do
      user = create(:user)

      # Note: Testing session persistence across requests in request specs is tricky
      # This is better tested in controller specs, but here we'll test with a single call
      # that checks if logged_in? returns true
      allow_any_instance_of(AuthController).to receive(:logged_in?).and_return(true)
      get auth_login_path
      expect(response).to redirect_to(dashboard_path)
    end
  end

  describe 'POST /auth/request_login' do
    it 'returns a successful response' do
      post auth_request_login_path, as: :json
      expect(response).to have_http_status(:ok)
    end

    it 'returns JSON with authorization URL' do
      post auth_request_login_path, as: :json
      body = JSON.parse(response.body)

      expect(body).to have_key('authorization_url')
      expect(body['authorization_url']).to include('https://web.line.biz/web/login')
    end

    it 'stores state in session' do
      post auth_request_login_path, as: :json
      expect(session[:line_login_state]).to be_present
    end

    it 'stores nonce in session' do
      post auth_request_login_path, as: :json
      expect(session[:line_login_nonce]).to be_present
    end

    it 'returns correct client_id in authorization URL' do
      post auth_request_login_path, as: :json
      body = JSON.parse(response.body)

      expect(body['authorization_url']).to include("client_id=#{line_channel_id}")
    end
  end

  describe 'GET /auth/line/callback' do
    let(:auth_code) { 'test_auth_code' }
    let(:line_user_id) { 'U1234567890abcdef1234567890abcdef' }
    let(:display_name) { 'TEST User' }
    let(:picture_url) { 'https://example.com/pic.jpg' }
    let(:access_token) { 'test_access_token' }
    let(:refresh_token) { 'test_refresh_token' }

    before do

      # Mock LINE API responses
      stub_request(:post, 'https://api.line.biz/v2.0/token').to_return(
        status: 200,
        body: JSON.generate(
          access_token: access_token,
          token_type: 'Bearer',
          expires_in: 2592000,
          refresh_token: refresh_token,
          scope: 'profile openid'
        ),
        headers: { 'Content-Type' => 'application/json' }
      )

      stub_request(:get, 'https://api.line.me/v2/profile').
        with(headers: { 'Authorization' => "Bearer #{access_token}" }).
        to_return(
          status: 200,
          body: JSON.generate(
            userId: line_user_id,
            displayName: display_name,
            pictureUrl: picture_url
          ),
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    def setup_valid_session
      # Request login first to setup session
      post auth_request_login_path, as: :json
    end

    it 'returns a redirect response' do
      setup_valid_session
      get auth_line_callback_path, params: { code: auth_code, state: session[:line_login_state] }
      expect(response).to have_http_status(:found)
    end

    it 'redirects to dashboard after successful login' do
      setup_valid_session
      state = session[:line_login_state]
      get auth_line_callback_path, params: { code: auth_code, state: state }
      expect(response).to redirect_to(dashboard_path)
    end

    it 'sets user session' do
      setup_valid_session
      state = session[:line_login_state]
      get auth_line_callback_path, params: { code: auth_code, state: state }
      expect(session[:user_id]).to be_present
    end

    it 'creates a new user and LINE account' do
      setup_valid_session
      state = session[:line_login_state]
      expect {
        get auth_line_callback_path, params: { code: auth_code, state: state }
      }.to change(User, :count).by(1)
        .and change(LineAccount, :count).by(1)
    end

    it 'logs in the user' do
      setup_valid_session
      state = session[:line_login_state]
      get auth_line_callback_path, params: { code: auth_code, state: state }
      follow_redirect!

      expect(response.body).to include(display_name)
    end

    context 'when state validation fails' do
      it 'returns bad request status' do
        setup_valid_session
        get auth_line_callback_path, params: { code: auth_code, state: 'invalid_state' }
        expect(response).to have_http_status(:bad_request)
      end

      it 'does not create new user' do
        setup_valid_session
        expect {
          get auth_line_callback_path, params: { code: auth_code, state: 'invalid_state' }
        }.not_to change(User, :count)
      end
    end

    context 'when authorization code is missing' do
      it 'returns bad request status' do
        setup_valid_session
        state = session[:line_login_state]
        get auth_line_callback_path, params: { state: state }
        expect(response).to have_http_status(:bad_request)
      end
    end
  end

  describe 'POST /auth/logout' do
    let(:user) { create(:user) }

    before do
      sign_in_as(user)
    end

    it 'clears session' do
      post auth_logout_path
      expect(session[:user_id]).to be_nil
    end

    it 'redirects to home page' do
      post auth_logout_path
      expect(response).to redirect_to(root_path)
    end

    it 'shows logout message' do
      post auth_logout_path
      follow_redirect!
      expect(response.body).to include('successfully')
    end
  end
end
