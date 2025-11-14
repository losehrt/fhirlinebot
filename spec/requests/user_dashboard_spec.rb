require 'rails_helper'

describe 'User Dashboard', type: :request do
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

  before do
    # Mock LineAuthService and LineLoginHandler to bypass environment variable validation
    allow_any_instance_of(LineAuthService).to receive(:validate_credentials!).and_return(true)
    allow_any_instance_of(LineLoginHandler).to receive(:validate_credentials!).and_return(true)
  end

  describe 'GET /dashboard' do
    context 'when user is not logged in' do
      it 'requires login' do
        get dashboard_path
        expect(response.status).to be_between(300, 399)
      end
    end

    context 'when user is logged in' do
      let(:user) { create(:user, :with_line_account) }

      before do
        allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
        allow_any_instance_of(ApplicationController).to receive(:logged_in?).and_return(true)
      end

      it 'returns a successful response' do
        get dashboard_path
        expect(response).to have_http_status(:ok)
      end

      it 'displays the dashboard page' do
        get dashboard_path
        body = response.body
        expect((body.include?('Dashboard') || body.include?('dashboard') || body.include?('Welcome'))).to be_truthy
      end

      it 'displays user display name' do
        get dashboard_path
        expect(response.body).to include(user.display_name)
      end
    end
  end

  describe 'GET /user_settings' do
    let(:user) { create(:user, :with_line_account) }

    before do
      allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
      allow_any_instance_of(ApplicationController).to receive(:logged_in?).and_return(true)
    end

    context 'when user is logged in' do
      it 'returns a successful response' do
        get user_settings_path
        expect(response).to have_http_status(:ok)
      end

      it 'displays user email' do
        get user_settings_path
        expect(response.body).to include(user.email)
      end

      it 'displays LINE account information' do
        get user_settings_path
        expect(response.body).to include(user.line_account.display_name)
      end

      it 'displays LINE User ID' do
        get user_settings_path
        expect(response.body).to include(user.line_account.line_user_id)
      end
    end

    context 'when user has no LINE account' do
      let(:user) { create(:user) }

      it 'displays option to connect LINE account' do
        get user_settings_path
        body = response.body
        expect((body.include?('LINE') || body.include?('Not Connected') || body.include?('connect'))).to be_truthy
      end
    end
  end

  describe 'DELETE /user/disconnect-line-account' do
    let(:user) { create(:user, :with_line_account) }

    before do
      allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
      allow_any_instance_of(ApplicationController).to receive(:logged_in?).and_return(true)
    end

    it 'disconnects LINE account from user' do
      expect {
        delete disconnect_line_account_path
      }.to change { user.reload.has_line_account? }.from(true).to(false)
    end

    it 'redirects to settings page' do
      delete disconnect_line_account_path
      expect(response).to redirect_to(user_settings_path)
    end

    it 'deletes LINE account record' do
      line_account_id = user.line_account.id
      delete disconnect_line_account_path

      expect(LineAccount.find_by(id: line_account_id)).to be_nil
    end

    context 'when user has no LINE account' do
      let(:user) { create(:user) }

      it 'returns error response' do
        delete disconnect_line_account_path
        expect([400, 422, 302]).to include(response.status)
      end
    end
  end

  describe 'GET /user/link-line-account' do
    let(:user) { create(:user) }

    before do
      allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
      allow_any_instance_of(ApplicationController).to receive(:logged_in?).and_return(true)
    end

    it 'returns a successful response' do
      get link_line_account_path
      expect(response).to have_http_status(:ok)
    end

    it 'displays link page' do
      get link_line_account_path
      body = response.body
      expect((body.include?('Link') || body.include?('Connect') || body.include?('LINE'))).to be_truthy
    end

    context 'when user already has LINE account' do
      let(:user) { create(:user, :with_line_account) }

      it 'redirects to settings page' do
        get link_line_account_path
        expect(response).to redirect_to(user_settings_path)
      end
    end
  end

  describe 'POST /user/request-line-link' do
    let(:user) { create(:user) }

    before do
      allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
      allow_any_instance_of(ApplicationController).to receive(:logged_in?).and_return(true)
    end

    it 'returns JSON with authorization URL' do
      post request_line_link_path, as: :json
      body = JSON.parse(response.body)
      expect(body).to have_key('authorization_url')
    end

    it 'stores link intent in session' do
      post request_line_link_path, as: :json
      expect(session[:line_link_intent]).to eq('link_account')
    end

    context 'when user already has LINE account' do
      let(:user) { create(:user, :with_line_account) }

      it 'returns error' do
        post request_line_link_path, as: :json
        expect(response).to have_http_status(:bad_request)
      end
    end
  end
end
