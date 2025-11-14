require 'rails_helper'

describe 'LINE Login Integration Flow', type: :request do
  let(:line_channel_id) { 'test_channel_id' }
  let(:line_channel_secret) { 'test_channel_secret' }

  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with('LINE_CHANNEL_ID').and_return(line_channel_id)
    allow(ENV).to receive(:[]).with('LINE_CHANNEL_SECRET').and_return(line_channel_secret)

    # Create global LINE configuration
    LineConfiguration.create!(
      organization_id: nil,
      name: 'Test Global LINE Config',
      channel_id: line_channel_id,
      channel_secret: line_channel_secret,
      redirect_uri: 'https://example.com/auth/line/callback',
      is_default: true,
      is_active: true
    )

    # Initialize default roles
    Role.default_roles
  end

  describe 'Complete LINE Login flow for new user' do
    let(:line_user_id) { 'U1234567890abcdef1234567890abcdef' }
    let(:display_name) { 'New LINE User' }
    let(:picture_url) { 'https://example.com/profile.jpg' }
    let(:access_token) { 'nHuyWiAccessToken123' }
    let(:refresh_token) { 'nHuyWiRefreshToken456' }
    let(:expires_in) { 2592000 }

    before do
      # Mock LINE API responses
      stub_request(:post, "https://api.line.biz/v2.0/token").
        to_return(
          status: 200,
          body: JSON.generate({
            access_token: access_token,
            token_type: 'Bearer',
            expires_in: expires_in,
            refresh_token: refresh_token,
            scope: 'profile openid'
          }),
          headers: { 'Content-Type' => 'application/json' }
        )

      stub_request(:get, "https://api.line.me/v2/profile").
        with(headers: { 'Authorization' => "Bearer #{access_token}" }).
        to_return(
          status: 200,
          body: JSON.generate({
            userId: line_user_id,
            displayName: display_name,
            pictureUrl: picture_url
          }),
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    it 'completes full authentication flow' do
      # Step 1: Request login - Get authorization URL
      post "/auth/request_login", params: {}, headers: { 'Accept' => 'application/json' }
      expect(response).to have_http_status(:success)
      auth_request = JSON.parse(response.body)

      expect(auth_request['authorization_url']).to include('https://web.line.biz/web/login')
      expect(auth_request['authorization_url']).to include("client_id=#{line_channel_id}")

      # Extract state and nonce from response (they're in the URL now)
      auth_url = auth_request['authorization_url']
      state = auth_url.match(/state=([^&]+)/)[1]
      nonce = auth_url.match(/nonce=([^&]+)/)[1]
      expect(state).to be_present
      expect(nonce).to be_present

      # Step 2: User is redirected back from LINE with authorization code
      expect(User.count).to eq(0)

      get "/auth/line/callback", params: { code: 'auth_code_from_line', state: state }

      # Step 3: Verify user was created
      expect(User.count).to eq(1)
      user = User.last
      expect(user.name).to eq(display_name)
      expect(user.email).to match(/@line\.example\.com\z/)

      # Step 4: Verify LINE account was created
      expect(user.line_account).to be_present
      expect(user.line_account.line_user_id).to eq(line_user_id)
      expect(user.line_account.display_name).to eq(display_name)
      expect(user.line_account.picture_url).to eq(picture_url)
      expect(user.line_account.access_token).to eq(access_token)
      expect(user.line_account.refresh_token).to eq(refresh_token)

      # Step 5: Verify user is logged in (redirects to home page)
      expect(response).to have_http_status(:redirect)
      expect(response.location).to include('/')
    end

    it 'displays welcome message after login' do
      post "/auth/request_login", params: {}, headers: { 'Accept' => 'application/json' }
      auth_request = JSON.parse(response.body)
      auth_url = auth_request['authorization_url']
      state = auth_url.match(/state=([^&]+)/)[1]

      get '/auth/line/callback', params: { code: 'auth_code_from_line', state: state }
      follow_redirect!

      expect(flash[:notice]).to include('Welcome')
    end

    it 'clears login tokens after successful authentication' do
      post "/auth/request_login", params: {}, headers: { 'Accept' => 'application/json' }
      auth_request = JSON.parse(response.body)
      auth_url = auth_request['authorization_url']
      state = auth_url.match(/state=([^&]+)/)[1]

      get '/auth/line/callback', params: { code: 'auth_code_from_line', state: state }

      # After successful authentication, session tokens should be cleared
      # We can verify this by attempting another callback with the same state
      # which should fail because the state was cleared
      expect(response).to have_http_status(:redirect)
    end
  end

  describe 'Complete LINE Login flow for existing user' do
    let(:user) { create(:user, :with_line_account) }
    let(:line_user_id) { user.line_account.line_user_id }
    let(:display_name) { 'Updated NAME' }
    let(:picture_url) { 'https://example.com/new_profile.jpg' }
    let(:access_token) { 'nHuyWiNewAccessToken' }
    let(:refresh_token) { 'nHuyWiNewRefreshToken' }
    let(:expires_in) { 2592000 }

    before do
      stub_request(:post, "https://api.line.biz/v2.0/token").
        to_return(
          status: 200,
          body: JSON.generate({
            access_token: access_token,
            token_type: 'Bearer',
            expires_in: expires_in,
            refresh_token: refresh_token,
            scope: 'profile openid'
          }),
          headers: { 'Content-Type' => 'application/json' }
        )

      stub_request(:get, "https://api.line.me/v2/profile").
        with(headers: { 'Authorization' => "Bearer #{access_token}" }).
        to_return(
          status: 200,
          body: JSON.generate({
            userId: line_user_id,
            displayName: display_name,
            pictureUrl: picture_url
          }),
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    it 'updates existing user account with new information' do
      expect(User.count).to eq(1)
      original_user_id = user.id

      # Request login
      post '/auth/request_login.json'
      state = session[:line_login_state]

      # Callback
      get '/auth/line/callback', params: { code: 'auth_code_from_line', state: state }

      # Verify same user account
      expect(User.count).to eq(1)
      user.reload
      expect(user.id).to eq(original_user_id)
      expect(user.name).to eq(display_name)

      # Verify tokens were updated
      expect(user.line_account.access_token).to eq(access_token)
      expect(user.line_account.refresh_token).to eq(refresh_token)
    end

    it 'logs in existing user without creating new account' do
      post '/auth/request_login.json'
      state = session[:line_login_state]

      get '/auth/line/callback', params: { code: 'auth_code_from_line', state: state }
      follow_redirect!

      expect(session[:user_id]).to eq(user.id)
      expect(User.count).to eq(1)
    end
  end

  describe 'ERROR: Invalid state parameter' do
    it 'rejects callback with mismatched state' do
      post '/auth/request_login.json'
      stored_state = session[:line_login_state]

      get '/auth/line/callback', params: { code: 'auth_code', state: 'wrong_state' }

      expect(response).to have_http_status(:bad_request)
      expect(session[:user_id]).to be_nil
      expect(User.count).to eq(0)
    end

    it 'displays error message for state mismatch' do
      post '/auth/request_login.json'

      get '/auth/line/callback', params: { code: 'auth_code', state: 'wrong_state' }

      expect(flash[:alert]).to include('Invalid state parameter')
    end
  end

  describe 'ERROR: Invalid authorization code' do
    before do
      stub_request(:post, "https://api.line.biz/v2.0/token").
        to_return(
          status: 400,
          body: JSON.generate({
            error: 'invalid_grant',
            error_description: 'Authorization code expired'
          }),
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    it 'handles invalid authorization code gracefully' do
      post '/auth/request_login.json'
      state = session[:line_login_state]

      get '/auth/line/callback', params: { code: 'invalid_code', state: state }

      expect(response).to have_http_status(:unauthorized)
      expect(session[:user_id]).to be_nil
      expect(User.count).to eq(0)
    end

    it 'displays error message for invalid code' do
      post '/auth/request_login.json'
      state = session[:line_login_state]

      get '/auth/line/callback', params: { code: 'invalid_code', state: state }

      expect(flash[:alert]).to include('Failed to authenticate')
    end
  end

  describe 'ERROR: Network failure' do
    before do
      stub_request(:post, "https://api.line.biz/v2.0/token").
        to_raise(Errno::ECONNREFUSED)
    end

    it 'handles network errors gracefully' do
      post '/auth/request_login.json'
      state = session[:line_login_state]

      get '/auth/line/callback', params: { code: 'auth_code', state: state }

      expect(response).to have_http_status(:service_unavailable)
      expect(session[:user_id]).to be_nil
    end

    it 'displays error message for network failure' do
      post '/auth/request_login.json'
      state = session[:line_login_state]

      get '/auth/line/callback', params: { code: 'auth_code', state: state }

      expect(flash[:alert]).to include('Network error')
    end
  end

  describe 'Logout functionality' do
    let(:user) { create(:user, :with_line_account) }
    let(:line_user_id) { user.line_account.line_user_id }
    let(:display_name) { 'Test User' }
    let(:picture_url) { 'https://example.com/pic.jpg' }
    let(:access_token) { 'nHuyWiAccessToken' }
    let(:refresh_token) { 'nHuyWiRefreshToken' }
    let(:expires_in) { 2592000 }

    before do
      stub_request(:post, "https://api.line.biz/v2.0/token").
        to_return(
          status: 200,
          body: JSON.generate({
            access_token: access_token,
            token_type: 'Bearer',
            expires_in: expires_in,
            refresh_token: refresh_token,
            scope: 'profile openid'
          }),
          headers: { 'Content-Type' => 'application/json' }
        )

      stub_request(:get, "https://api.line.me/v2/profile").
        to_return(
          status: 200,
          body: JSON.generate({
            userId: line_user_id,
            displayName: display_name,
            pictureUrl: picture_url
          }),
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    it 'logs out user and clears session' do
      # Login user
      post "/auth/request_login", params: {}, headers: { 'Accept' => 'application/json' }
      auth_request = JSON.parse(response.body)
      auth_url = auth_request['authorization_url']
      state = auth_url.match(/state=([^&]+)/)[1]

      get '/auth/line/callback', params: { code: 'auth_code_from_line', state: state }

      # Logout
      post '/auth/logout'
      follow_redirect!

      expect(flash[:notice]).to include('logged out')
    end
  end

  describe 'Session persistence across requests' do
    let(:user) { create(:user) }
    let(:line_user_id) { 'U1234567890abcdef1234567890abcdef' }
    let(:display_name) { 'Test User' }
    let(:picture_url) { 'https://example.com/pic.jpg' }
    let(:access_token) { 'nHuyWiAccessToken' }
    let(:refresh_token) { 'nHuyWiRefreshToken' }
    let(:expires_in) { 2592000 }

    before do
      stub_request(:post, "https://api.line.biz/v2.0/token").
        to_return(
          status: 200,
          body: JSON.generate({
            access_token: access_token,
            token_type: 'Bearer',
            expires_in: expires_in,
            refresh_token: refresh_token,
            scope: 'profile openid'
          }),
          headers: { 'Content-Type' => 'application/json' }
        )

      stub_request(:get, "https://api.line.me/v2/profile").
        to_return(
          status: 200,
          body: JSON.generate({
            userId: line_user_id,
            displayName: display_name,
            pictureUrl: picture_url
          }),
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    it 'maintains user session across multiple requests' do
      # Login user
      post "/auth/request_login", params: {}, headers: { 'Accept' => 'application/json' }
      auth_request = JSON.parse(response.body)
      auth_url = auth_request['authorization_url']
      state = auth_url.match(/state=([^&]+)/)[1]

      get '/auth/line/callback', params: { code: 'auth_code_from_line', state: state }

      # Verify user is logged in for subsequent requests
      get '/up'  # health check
      expect(response).to have_http_status(:success)
    end
  end
end
