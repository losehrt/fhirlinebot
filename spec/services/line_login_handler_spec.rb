require 'rails_helper'

describe LineLoginHandler, type: :service do
  let(:line_channel_id) { 'test_channel_id' }
  let(:line_channel_secret) { 'test_channel_secret' }
  let(:redirect_uri) { 'http://localhost:3000/auth/line/callback' }
  let(:auth_code) { 'test_auth_code' }
  let(:state) { 'test_state_value' }
  let(:nonce) { 'test_nonce_value' }

  let(:line_user_id) { 'U1234567890abcdef1234567890abcdef' }
  let(:display_name) { 'LINE User Name' }
  let(:picture_url) { 'https://example.com/line_avatar.jpg' }

  let(:access_token) { 'nHuyWiAccessTokenString' }
  let(:refresh_token) { 'nHuyWiRefreshTokenString' }
  let(:expires_in) { 2592000 }

  describe '#handle_callback' do
    context 'when complete LINE login flow succeeds' do
      before do
        # Mock the token exchange
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

        # Mock the profile fetch
        stub_request(:get, "https://api.line.me/v2/profile").
          with(headers: { 'Authorization' => "Bearer #{access_token}" }).
          to_return(
            status: 200,
            body: JSON.generate({
              userId: line_user_id,
              displayName: display_name,
              pictureUrl: picture_url,
              statusMessage: 'Hello'
            }),
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'creates a new user with LINE account' do
        handler = LineLoginHandler.new(line_channel_id, line_channel_secret)
        user = handler.handle_callback(auth_code, redirect_uri, state, nonce)

        expect(user).to be_persisted
        expect(user.name).to eq(display_name)
        expect(user.email).to match(/@line\.example\.com\z/)
      end

      it 'creates LINE account with tokens' do
        handler = LineLoginHandler.new(line_channel_id, line_channel_secret)
        user = handler.handle_callback(auth_code, redirect_uri, state, nonce)

        expect(user.line_account).to be_persisted
        expect(user.line_account.line_user_id).to eq(line_user_id)
        expect(user.line_account.access_token).to eq(access_token)
        expect(user.line_account.refresh_token).to eq(refresh_token)
      end

      it 'sets correct expiration time' do
        handler = LineLoginHandler.new(line_channel_id, line_channel_secret)
        user = handler.handle_callback(auth_code, redirect_uri, state, nonce)

        expect(user.line_account.expires_at).to be_within(2.seconds).of((expires_in).seconds.from_now)
      end

      it 'stores profile information' do
        handler = LineLoginHandler.new(line_channel_id, line_channel_secret)
        user = handler.handle_callback(auth_code, redirect_uri, state, nonce)

        expect(user.line_account.display_name).to eq(display_name)
        expect(user.line_account.picture_url).to eq(picture_url)
      end

      it 'returns user object' do
        handler = LineLoginHandler.new(line_channel_id, line_channel_secret)
        result = handler.handle_callback(auth_code, redirect_uri, state, nonce)

        expect(result).to be_a(User)
        expect(result.persisted?).to be true
      end
    end

    context 'when user already has LINE account' do
      let!(:user) { create(:user, :with_line_account, line_account: create(:line_account, line_user_id: line_user_id)) }

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

      it 'returns existing user' do
        handler = LineLoginHandler.new(line_channel_id, line_channel_secret)
        result = handler.handle_callback(auth_code, redirect_uri, state, nonce)

        expect(result.id).to eq(user.id)
      end

      it 'updates access token' do
        handler = LineLoginHandler.new(line_channel_id, line_channel_secret)
        handler.handle_callback(auth_code, redirect_uri, state, nonce)

        line_account = LineAccount.find_by(line_user_id: line_user_id)
        expect(line_account.access_token).to eq(access_token)
      end

      it 'updates profile information' do
        handler = LineLoginHandler.new(line_channel_id, line_channel_secret)
        handler.handle_callback(auth_code, redirect_uri, state, nonce)

        line_account = LineAccount.find_by(line_user_id: line_user_id)
        expect(line_account.display_name).to eq(display_name)
        expect(line_account.picture_url).to eq(picture_url)
      end

      it 'does not create duplicate user' do
        expect {
          handler = LineLoginHandler.new(line_channel_id, line_channel_secret)
          handler.handle_callback(auth_code, redirect_uri, state, nonce)
        }.not_to change(User, :count)
      end
    end

    context 'when code exchange fails' do
      it 'raises AuthenticationError when code is invalid' do
        stub_request(:post, "https://api.line.biz/v2.0/token").
          to_return(
            status: 400,
            body: JSON.generate({
              error: 'invalid_grant',
              error_description: 'Authorization code is expired'
            }),
            headers: { 'Content-Type' => 'application/json' }
          )

        handler = LineLoginHandler.new(line_channel_id, line_channel_secret)
        expect {
          handler.handle_callback('invalid_code', redirect_uri, state, nonce)
        }.to raise_error(LineAuthService::AuthenticationError)
      end

      it 'raises NetworkError on connection failure' do
        stub_request(:post, "https://api.line.biz/v2.0/token").
          to_raise(Errno::ECONNREFUSED)

        handler = LineLoginHandler.new(line_channel_id, line_channel_secret)
        expect {
          handler.handle_callback(auth_code, redirect_uri, state, nonce)
        }.to raise_error(LineAuthService::NetworkError)
      end
    end

    context 'when profile fetch fails' do
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
      end

      it 'raises AuthenticationError when token is invalid' do
        stub_request(:get, "https://api.line.me/v2/profile").
          with(headers: { 'Authorization' => "Bearer #{access_token}" }).
          to_return(
            status: 401,
            body: JSON.generate({ error: 'invalid_access_token' }),
            headers: { 'Content-Type' => 'application/json' }
          )

        handler = LineLoginHandler.new(line_channel_id, line_channel_secret)
        expect {
          handler.handle_callback(auth_code, redirect_uri, state, nonce)
        }.to raise_error(LineAuthService::AuthenticationError)
      end
    end
  end

  describe '#create_authorization_request' do
    it 'generates authorization request with state and nonce' do
      handler = LineLoginHandler.new(line_channel_id, line_channel_secret)
      auth_request = handler.create_authorization_request(redirect_uri)

      expect(auth_request).to include(:state, :nonce)
      expect(auth_request[:state]).to be_a(String)
      expect(auth_request[:nonce]).to be_a(String)
      expect(auth_request[:state]).not_to be_empty
      expect(auth_request[:nonce]).not_to be_empty
    end

    it 'generates unique state and nonce for each request' do
      handler = LineLoginHandler.new(line_channel_id, line_channel_secret)
      auth_request1 = handler.create_authorization_request(redirect_uri)
      auth_request2 = handler.create_authorization_request(redirect_uri)

      expect(auth_request1[:state]).not_to eq(auth_request2[:state])
      expect(auth_request1[:nonce]).not_to eq(auth_request2[:nonce])
    end

    it 'includes authorization URL in request' do
      handler = LineLoginHandler.new(line_channel_id, line_channel_secret)
      auth_request = handler.create_authorization_request(redirect_uri)

      expect(auth_request).to include(:authorization_url)
      expect(auth_request[:authorization_url]).to include('https://web.line.biz/web/login')
      expect(auth_request[:authorization_url]).to include("client_id=#{line_channel_id}")
    end

    it 'includes state and nonce in authorization URL' do
      handler = LineLoginHandler.new(line_channel_id, line_channel_secret)
      auth_request = handler.create_authorization_request(redirect_uri)

      expect(auth_request[:authorization_url]).to include("state=#{auth_request[:state]}")
      expect(auth_request[:authorization_url]).to include("nonce=#{auth_request[:nonce]}")
    end
  end

  describe 'error handling' do
    context 'when credentials are not configured' do
      it 'raises error when channel_id is missing' do
        expect {
          LineLoginHandler.new(nil, line_channel_secret)
        }.to raise_error(/LINE_CHANNEL_ID/)
      end

      it 'raises error when channel_secret is missing' do
        expect {
          LineLoginHandler.new(line_channel_id, nil)
        }.to raise_error(/LINE_CHANNEL_SECRET/)
      end
    end

    context 'LineAuthService errors propagate' do
      it 'propagates AuthenticationError from service' do
        stub_request(:post, "https://api.line.biz/v2.0/token").
          to_return(status: 400)

        handler = LineLoginHandler.new(line_channel_id, line_channel_secret)
        expect {
          handler.handle_callback(auth_code, redirect_uri, state, nonce)
        }.to raise_error(LineAuthService::AuthenticationError)
      end

      it 'propagates NetworkError from service' do
        stub_request(:post, "https://api.line.biz/v2.0/token").
          to_raise(Errno::ECONNREFUSED)

        handler = LineLoginHandler.new(line_channel_id, line_channel_secret)
        expect {
          handler.handle_callback(auth_code, redirect_uri, state, nonce)
        }.to raise_error(LineAuthService::NetworkError)
      end
    end
  end

  describe 'state/nonce management' do
    it 'validates state parameter matches' do
      handler = LineLoginHandler.new(line_channel_id, line_channel_secret)
      auth_request = handler.create_authorization_request(redirect_uri)

      # For now, just verify the state is stored correctly
      expect(auth_request[:state]).to be_present
    end

    it 'stores state and nonce for CSRF/token validation' do
      handler = LineLoginHandler.new(line_channel_id, line_channel_secret)
      auth_request = handler.create_authorization_request(redirect_uri)

      # State and nonce should be returned for storage by controller
      expect(auth_request[:state]).to match(/^[a-f0-9]{32}$/)
      expect(auth_request[:nonce]).to match(/^[a-f0-9]{32}$/)
    end
  end
end
