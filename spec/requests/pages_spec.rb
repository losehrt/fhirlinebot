require 'rails_helper'

RSpec.describe 'Pages', type: :request do
  describe 'GET /home' do
    it 'returns 200 OK' do
      get '/'
      expect(response).to have_http_status(:ok)
    end

    it 'renders the home template' do
      get '/'
      expect(response).to render_template(:home)
    end

    it 'does not require setup completion' do
      # home 頁面應該可以被未完成設置的用戶訪問
      get '/'
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'GET /dashboard' do
    it 'returns 200 OK' do
      get '/dashboard'
      expect(response).to have_http_status(:ok)
    end

    it 'renders the dashboard template' do
      get '/dashboard'
      expect(response).to render_template('dashboard/show')
    end
  end

  describe 'GET /profile' do
    it 'redirects when not logged in' do
      get '/profile'
      expect(response).to have_http_status(:found)
    end

    it 'redirects to setup when user not configured' do
      get '/profile'
      expect(response).to redirect_to('/setup')
    end
  end
end
