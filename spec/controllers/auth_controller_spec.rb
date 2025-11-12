require 'rails_helper'

describe AuthController, type: :controller do
  let(:line_channel_id) { 'test_channel_id' }
  let(:line_channel_secret) { 'test_channel_secret' }

  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with('LINE_CHANNEL_ID').and_return(line_channel_id)
    allow(ENV).to receive(:[]).with('LINE_CHANNEL_SECRET').and_return(line_channel_secret)
  end

  describe 'POST #request_login' do
    let(:redirect_uri) { 'http://localhost:3000/auth/line/callback' }

    it 'handles login request' do
      post :request_login, as: :json
      expect(response).to have_http_status(:success)
    end

    it 'stores state in session' do
      post :request_login, as: :json
      expect(session[:line_login_state]).to be_present
    end

    it 'stores nonce in session' do
      post :request_login, as: :json
      expect(session[:line_login_nonce]).to be_present
    end

    it 'returns authorization URL' do
      post :request_login, as: :json
      body = JSON.parse(response.body)

      expect(body['authorization_url']).to include('https://web.line.biz/web/login')
      expect(body['authorization_url']).to include("client_id=#{line_channel_id}")
    end

    it 'state in session matches URL' do
      post :request_login, as: :json
      body = JSON.parse(response.body)

      expect(body['authorization_url']).to include("state=#{session[:line_login_state]}")
    end

    it 'nonce in session matches URL' do
      post :request_login, as: :json
      body = JSON.parse(response.body)

      expect(body['authorization_url']).to include("nonce=#{session[:line_login_nonce]}")
    end
  end

  describe 'GET #callback' do
    let(:auth_code) { 'test_auth_code' }
    let(:line_user_id) { 'U1234567890abcdef1234567890abcdef' }
    let(:display_name) { 'TEST User' }
    let(:picture_url) { 'https://example.com/pic.jpg' }
    let(:access_token) { 'test_access_token' }
    let(:refresh_token) { 'test_refresh_token' }
    let(:expires_in) { 2592000 }

    context 'when LINE login succeeds' do
      before do
        # Setup session state and nonce
        session[:line_login_state] = 'state_value'
        session[:line_login_nonce] = 'nonce_value'

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

      it 'authenticates user' do
        get :callback, params: { code: auth_code, state: 'state_value' }

        expect(session[:user_id]).to be_present
      end

      it 'redirects to dashboard after successful login' do
        get :callback, params: { code: auth_code, state: 'state_value' }

        expect(response).to redirect_to('/')
      end

      it 'creates user if does not exist' do
        expect {
          get :callback, params: { code: auth_code, state: 'state_value' }
        }.to change(User, :count).by(1)
      end

      it 'updates user if already exists' do
        user = create(:user, :with_line_account, line_account: create(:line_account, line_user_id: line_user_id))

        expect {
          get :callback, params: { code: auth_code, state: 'state_value' }
        }.not_to change(User, :count)
      end

      it 'sets flash message on success' do
        get :callback, params: { code: auth_code, state: 'state_value' }

        expect(flash[:notice]).to be_present
      end

      it 'clears session state after login' do
        get :callback, params: { code: auth_code, state: 'state_value' }

        expect(session[:line_login_state]).to be_nil
        expect(session[:line_login_nonce]).to be_nil
      end
    end

    context 'when state parameter does not match' do
      before do
        session[:line_login_state] = 'expected_state'
      end

      it 'rejects request with mismatched state' do
        get :callback, params: { code: auth_code, state: 'wrong_state' }

        expect(response).to have_http_status(:bad_request)
      end

      it 'sets error flash message' do
        get :callback, params: { code: auth_code, state: 'wrong_state' }

        expect(flash[:alert]).to be_present
      end

      it 'does not create user session' do
        get :callback, params: { code: auth_code, state: 'wrong_state' }

        expect(session[:user_id]).to be_nil
      end
    end

    context 'when state parameter is missing' do
      it 'returns error' do
        get :callback, params: { code: auth_code }

        expect(response).to have_http_status(:bad_request)
      end
    end

    context 'when authorization code is invalid' do
      before do
        session[:line_login_state] = 'state_value'

        stub_request(:post, "https://api.line.biz/v2.0/token").
          to_return(
            status: 400,
            body: JSON.generate({
              error: 'invalid_grant',
              error_description: 'Authorization code is expired'
            }),
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'handles authentication error' do
        get :callback, params: { code: 'invalid_code', state: 'state_value' }

        expect(response).to have_http_status(:unauthorized)
      end

      it 'displays error message' do
        get :callback, params: { code: 'invalid_code', state: 'state_value' }

        expect(flash[:alert]).to be_present
      end

      it 'does not create user session' do
        get :callback, params: { code: 'invalid_code', state: 'state_value' }

        expect(session[:user_id]).to be_nil
      end
    end

    context 'when network error occurs' do
      before do
        session[:line_login_state] = 'state_value'

        stub_request(:post, "https://api.line.biz/v2.0/token").
          to_raise(Errno::ECONNREFUSED)
      end

      it 'handles network error gracefully' do
        get :callback, params: { code: auth_code, state: 'state_value' }

        expect(response).to have_http_status(:service_unavailable)
      end

      it 'displays error message' do
        get :callback, params: { code: auth_code, state: 'state_value' }

        expect(flash[:alert]).to be_present
      end
    end
  end

  describe 'POST #logout' do
    let(:user) { create(:user) }

    before do
      session[:user_id] = user.id
    end

    it 'clears user session' do
      post :logout

      expect(session[:user_id]).to be_nil
    end

    it 'redirects to root after logout' do
      post :logout

      expect(response).to redirect_to('/')
    end

    it 'sets flash message' do
      post :logout

      expect(flash[:notice]).to be_present
    end
  end

  describe 'Session helpers' do
    context 'when user is logged in' do
      let(:user) { create(:user) }

      before do
        session[:user_id] = user.id
      end

      it 'sets user_id in session' do
        expect(session[:user_id]).to eq(user.id)
      end
    end

    context 'when user is not logged in' do
      it 'has no user_id in session' do
        expect(session[:user_id]).to be_nil
      end
    end
  end
end
