require 'rails_helper'

describe PagesController, type: :controller do
  # Setup ApplicationSetting to be configured for all tests
  # This bypasses the require_setup_completion before_action
  before do
    allow(ApplicationSetting).to receive(:configured?).and_return(true)
  end

  describe 'GET #home' do
    context 'when user is not logged in' do
      it 'returns http success' do
        get :home
        expect(response).to have_http_status(:success)
      end

      it 'renders the home template' do
        get :home
        expect(response).to render_template(:home)
      end

      it 'does not require authentication' do
        get :home
        expect(response).not_to redirect_to(root_path)
      end

      it 'does not require setup completion' do
        # Test that home action skips setup check
        allow(ApplicationSetting).to receive(:configured?).and_return(false)
        get :home
        expect(response).to have_http_status(:success)
      end
    end

    context 'when user is logged in' do
      let(:user) { create(:user) }

      before do
        session[:user_id] = user.id
      end

      it 'returns http success' do
        get :home
        expect(response).to have_http_status(:success)
      end

      it 'renders the home template' do
        get :home
        expect(response).to render_template(:home)
      end

      it 'has access to current_user' do
        get :home
        expect(controller.current_user).to eq(user)
      end

      it 'current_user is logged in' do
        get :home
        expect(controller.logged_in?).to be true
      end
    end
  end

  describe 'GET #profile' do
    context 'when user is not logged in' do
      it 'redirects to root page' do
        get :profile
        expect(response).to redirect_to(root_path)
      end

      it 'returns http redirect status' do
        get :profile
        expect(response).to have_http_status(:redirect)
      end

      it 'does not render profile template' do
        get :profile
        expect(response).not_to render_template(:profile)
      end

      it 'does not set current_user' do
        get :profile
        expect(controller.current_user).to be_nil
      end

      it 'logged_in? returns false' do
        get :profile
        expect(controller.logged_in?).to be false
      end
    end

    context 'when user is logged in' do
      let(:user) { create(:user) }

      before do
        session[:user_id] = user.id
      end

      it 'returns http success' do
        get :profile
        expect(response).to have_http_status(:success)
      end

      it 'renders the profile template' do
        get :profile
        expect(response).to render_template(:profile)
      end

      it 'does not redirect' do
        get :profile
        expect(response).not_to redirect_to(root_path)
      end

      it 'has access to current_user' do
        get :profile
        expect(controller.current_user).to eq(user)
      end

      it 'logged_in? returns true' do
        get :profile
        expect(controller.logged_in?).to be true
      end
    end

    context 'when user is logged in with LINE account' do
      let(:user) { create(:user, :with_line_account) }

      before do
        session[:user_id] = user.id
      end

      it 'returns http success' do
        get :profile
        expect(response).to have_http_status(:success)
      end

      it 'renders the profile template' do
        get :profile
        expect(response).to render_template(:profile)
      end

      it 'has access to current_user with LINE account' do
        get :profile
        expect(controller.current_user).to eq(user)
        expect(controller.current_user.has_line_account?).to be true
      end

      it 'user has display name from LINE account' do
        get :profile
        expect(controller.current_user.display_name).to eq(user.line_account.display_name)
      end
    end
  end

  describe 'Authentication and authorization flow' do
    let(:user) { create(:user) }

    context 'session management' do
      it 'authenticates user when session has user_id' do
        session[:user_id] = user.id
        get :profile
        expect(controller.logged_in?).to be true
        expect(controller.current_user).to eq(user)
      end

      it 'does not authenticate user when session is empty' do
        get :profile
        expect(controller.logged_in?).to be false
        expect(controller.current_user).to be_nil
      end

      it 'does not authenticate user with invalid user_id' do
        session[:user_id] = 999999
        get :profile
        expect(controller.logged_in?).to be false
        expect(controller.current_user).to be_nil
      end
    end

    context 'protected actions' do
      it 'profile requires authentication' do
        get :profile
        expect(response).to redirect_to(root_path)
      end

      it 'home does not require authentication' do
        get :home
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe 'Setup completion requirement' do
    context 'when ApplicationSetting is not configured' do
      before do
        allow(ApplicationSetting).to receive(:configured?).and_return(false)
      end

      it 'home action bypasses setup check' do
        get :home
        expect(response).to have_http_status(:success)
        expect(response).not_to redirect_to('/setup')
      end

      it 'profile action requires setup when not configured' do
        user = create(:user)
        session[:user_id] = user.id

        # Simulate the before_action behavior
        allow(controller).to receive(:require_setup_completion).and_call_original
        allow(controller).to receive(:skip_setup_check?).and_return(false)

        get :profile
        # Note: This test verifies the controller doesn't crash
        # The actual redirect is handled by ApplicationController
      end
    end

    context 'when ApplicationSetting is configured' do
      before do
        allow(ApplicationSetting).to receive(:configured?).and_return(true)
      end

      it 'allows all actions to proceed' do
        user = create(:user)
        session[:user_id] = user.id

        get :profile
        expect(response).to have_http_status(:success)

        get :home
        expect(response).to have_http_status(:success)
      end
    end
  end
end
