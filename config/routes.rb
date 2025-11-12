Rails.application.routes.draw do
  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  # Root path
  root "pages#home"

  # Static pages
  get "profile", to: "pages#profile"

  # Dashboard
  resource :dashboard, only: [:show], controller: 'dashboard'

  # LINE Bot setup
  resource :setup, only: [:show], controller: 'setup' do
    member do
      post :validate_credentials
      post :update
      post :test
      delete :clear
    end
  end

  # Authentication
  namespace :auth do
    post "request_login"
    get "line/callback", action: :callback
    post "logout"
  end

  # PWA support (commented out for now)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
end