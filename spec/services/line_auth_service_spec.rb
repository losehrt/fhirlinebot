require 'rails_helper'

describe LineAuthService, type: :service do
  let(:line_channel_id) { 'test_channel_id_12345' }
  let(:line_channel_secret) { 'test_channel_secret_67890' }
  let(:redirect_uri) { 'http://localhost:3000/auth/line/callback' }
  let(:auth_code) { 'test_auth_code_12345' }

  describe '#exchange_code!' do
    context 'when exchanging authorization code successfully' do
      before do
        stub_request(:post, "https://api.line.biz/v2.0/token").
          to_return(
            status: 200,
            body: JSON.generate({
              access_token: 'nHuyWiAccessToken',
              token_type: 'Bearer',
              expires_in: 2592000,
              refresh_token: 'nHuyWiRefreshToken',
              scope: 'profile openid'
            }),
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'returns token response with access_token' do
        service = LineAuthService.new(line_channel_id, line_channel_secret)
        response = service.exchange_code!(auth_code, redirect_uri)

        expect(response[:access_token]).to eq('nHuyWiAccessToken')
        expect(response[:token_type]).to eq('Bearer')
        expect(response[:expires_in]).to eq(2592000)
      end

      it 'includes refresh_token in response' do
        service = LineAuthService.new(line_channel_id, line_channel_secret)
        response = service.exchange_code!(auth_code, redirect_uri)

        expect(response[:refresh_token]).to eq('nHuyWiRefreshToken')
      end

      it 'includes scope in response' do
        service = LineAuthService.new(line_channel_id, line_channel_secret)
        response = service.exchange_code!(auth_code, redirect_uri)

        expect(response[:scope]).to eq('profile openid')
      end
    end

    context 'when LINE API returns error' do
      it 'raises error when invalid authorization code' do
        stub_request(:post, "https://api.line.biz/v2.0/token").
          to_return(
            status: 400,
            body: JSON.generate({
              error: 'invalid_grant',
              error_description: 'Authorization code is expired'
            }),
            headers: { 'Content-Type' => 'application/json' }
          )

        service = LineAuthService.new(line_channel_id, line_channel_secret)
        expect {
          service.exchange_code!('invalid_code', redirect_uri)
        }.to raise_error(LineAuthService::AuthenticationError)
      end

      it 'raises error on network failure' do
        service = LineAuthService.new(line_channel_id, line_channel_secret)
        allow(HTTParty).to receive(:post).and_raise(Timeout::Error)

        expect {
          service.exchange_code!(auth_code, redirect_uri)
        }.to raise_error(LineAuthService::NetworkError)
      end
    end
  end

  describe '#fetch_profile!' do
    let(:access_token) { 'nHuyWiSomeReallyLongAccessTokenString' }

    context 'when fetching profile successfully' do
      before do
        stub_request(:get, "https://api.line.me/v2/profile").
          with(headers: { 'Authorization' => "Bearer #{access_token}" }).
          to_return(
            status: 200,
            body: JSON.generate({
              userId: 'U12345678901234567890123456789012',
              displayName: 'John Doe',
              pictureUrl: 'https://example.com/pic.jpg',
              statusMessage: 'Hello LINE'
            }),
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'returns user profile with userId' do
        service = LineAuthService.new(line_channel_id, line_channel_secret)
        profile = service.fetch_profile!(access_token)

        expect(profile[:userId]).to eq('U12345678901234567890123456789012')
        expect(profile[:userId]).to match(/^U/)
      end

      it 'includes displayName in response' do
        service = LineAuthService.new(line_channel_id, line_channel_secret)
        profile = service.fetch_profile!(access_token)

        expect(profile[:displayName]).to eq('John Doe')
      end

      it 'includes pictureUrl in response' do
        service = LineAuthService.new(line_channel_id, line_channel_secret)
        profile = service.fetch_profile!(access_token)

        expect(profile[:pictureUrl]).to eq('https://example.com/pic.jpg')
      end

      it 'includes statusMessage if available' do
        service = LineAuthService.new(line_channel_id, line_channel_secret)
        profile = service.fetch_profile!(access_token)

        expect(profile).to include(:userId, :displayName, :pictureUrl)
      end
    end

    context 'when access token is invalid' do
      it 'raises AuthenticationError on 401 response' do
        stub_request(:get, "https://api.line.me/v2/profile").
          with(headers: { 'Authorization' => 'Bearer invalid_token' }).
          to_return(
            status: 401,
            body: JSON.generate({ error: 'invalid_access_token' }),
            headers: { 'Content-Type' => 'application/json' }
          )

        service = LineAuthService.new(line_channel_id, line_channel_secret)
        expect {
          service.fetch_profile!('invalid_token')
        }.to raise_error(LineAuthService::AuthenticationError)
      end

      it 'raises AuthenticationError on 403 response' do
        stub_request(:get, "https://api.line.me/v2/profile").
          with(headers: { 'Authorization' => 'Bearer expired_token' }).
          to_return(
            status: 403,
            body: JSON.generate({ error: 'forbidden' }),
            headers: { 'Content-Type' => 'application/json' }
          )

        service = LineAuthService.new(line_channel_id, line_channel_secret)
        expect {
          service.fetch_profile!('expired_token')
        }.to raise_error(LineAuthService::AuthenticationError)
      end
    end

    context 'when network error occurs' do
      it 'raises NetworkError on connection timeout' do
        service = LineAuthService.new(line_channel_id, line_channel_secret)
        allow(HTTParty).to receive(:get).and_raise(Net::OpenTimeout)

        expect {
          service.fetch_profile!(access_token)
        }.to raise_error(LineAuthService::NetworkError)
      end

      it 'raises NetworkError on SSL error' do
        service = LineAuthService.new(line_channel_id, line_channel_secret)
        allow(HTTParty).to receive(:get).and_raise(OpenSSL::SSL::SSLError)

        expect {
          service.fetch_profile!(access_token)
        }.to raise_error(LineAuthService::NetworkError)
      end
    end
  end

  describe '#refresh_token!' do
    let(:refresh_token) { 'nHuyWiSomeReallyLongRefreshTokenString' }

    context 'when refreshing token successfully' do
      before do
        stub_request(:post, "https://api.line.biz/v2.0/token").
          with(body: hash_including({ grant_type: 'refresh_token', refresh_token: refresh_token })).
          to_return(
            status: 200,
            body: JSON.generate({
              access_token: 'nHuyWiNewAccessToken',
              token_type: 'Bearer',
              expires_in: 2592000,
              refresh_token: 'nHuyWiNewRefreshToken'
            }),
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'returns new access_token' do
        service = LineAuthService.new(line_channel_id, line_channel_secret)
        response = service.refresh_token!(refresh_token)

        expect(response[:access_token]).to eq('nHuyWiNewAccessToken')
        expect(response[:access_token]).not_to eq(refresh_token)
      end

      it 'returns new expires_in value' do
        service = LineAuthService.new(line_channel_id, line_channel_secret)
        response = service.refresh_token!(refresh_token)

        expect(response[:expires_in]).to eq(2592000)
        expect(response[:expires_in]).to be > 0
      end

      it 'returns token_type as Bearer' do
        service = LineAuthService.new(line_channel_id, line_channel_secret)
        response = service.refresh_token!(refresh_token)

        expect(response[:token_type]).to eq('Bearer')
      end
    end

    context 'when refresh_token is invalid' do
      it 'raises AuthenticationError' do
        stub_request(:post, "https://api.line.biz/v2.0/token").
          with(body: hash_including({ grant_type: 'refresh_token', refresh_token: 'invalid_refresh_token' })).
          to_return(
            status: 400,
            body: JSON.generate({
              error: 'invalid_grant',
              error_description: 'Invalid refresh token'
            }),
            headers: { 'Content-Type' => 'application/json' }
          )

        service = LineAuthService.new(line_channel_id, line_channel_secret)
        expect {
          service.refresh_token!('invalid_refresh_token')
        }.to raise_error(LineAuthService::AuthenticationError)
      end
    end

    context 'when refresh_token is expired' do
      it 'raises AuthenticationError' do
        stub_request(:post, "https://api.line.biz/v2.0/token").
          with(body: hash_including({ grant_type: 'refresh_token', refresh_token: 'expired_refresh_token' })).
          to_return(
            status: 400,
            body: JSON.generate({
              error: 'invalid_grant',
              error_description: 'Refresh token expired'
            }),
            headers: { 'Content-Type' => 'application/json' }
          )

        service = LineAuthService.new(line_channel_id, line_channel_secret)
        expect {
          service.refresh_token!('expired_refresh_token')
        }.to raise_error(LineAuthService::AuthenticationError)
      end
    end
  end

  describe '#get_authorization_url' do
    let(:state) { 'state_parameter_for_csrf' }
    let(:nonce) { 'nonce_for_id_token' }

    context 'with required parameters' do
      it 'returns valid authorization URL' do
        service = LineAuthService.new(line_channel_id, line_channel_secret)
        url = service.get_authorization_url(redirect_uri, state, nonce)

        expect(url).to include('https://web.line.biz/web/login')
        expect(url).to include("client_id=#{line_channel_id}")
        expect(url).to include("redirect_uri=#{CGI.escape(redirect_uri)}")
        expect(url).to include("state=#{state}")
        expect(url).to include("nonce=#{nonce}")
      end

      it 'includes response_type=code' do
        service = LineAuthService.new(line_channel_id, line_channel_secret)
        url = service.get_authorization_url(redirect_uri, state, nonce)

        expect(url).to include('response_type=code')
      end

      it 'includes scope with profile and openid' do
        service = LineAuthService.new(line_channel_id, line_channel_secret)
        url = service.get_authorization_url(redirect_uri, state, nonce)

        expect(url).to match(/scope=profile[+%20]openid/)
      end
    end

    context 'with custom scope' do
      it 'includes custom scopes in URL' do
        service = LineAuthService.new(line_channel_id, line_channel_secret)
        custom_scopes = 'profile openid email'
        url = service.get_authorization_url(redirect_uri, state, nonce, scope: custom_scopes)

        expect(url).to include(CGI.escape(custom_scopes))
      end
    end
  end

  describe 'error handling' do
    describe 'LineAuthService::AuthenticationError' do
      it 'is raised for authentication failures' do
        expect {
          raise LineAuthService::AuthenticationError, 'Invalid credentials'
        }.to raise_error(LineAuthService::AuthenticationError)
      end
    end

    describe 'LineAuthService::NetworkError' do
      it 'is raised for network failures' do
        expect {
          raise LineAuthService::NetworkError, 'Connection timeout'
        }.to raise_error(LineAuthService::NetworkError)
      end
    end
  end
end
