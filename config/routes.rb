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
    get "login", action: :login
    post "request_login"
    get "line/callback", action: :callback
    post "logout"
  end

  # User Management
  resource :user_settings, only: [:show], controller: 'user_settings', as: 'user_settings'
  delete 'user/disconnect-line-account', to: 'users#disconnect_line_account', as: 'disconnect_line_account'
  get 'user/link-line-account', to: 'users#link_line_account', as: 'link_line_account'
  post 'user/request-line-link', to: 'users#request_line_link', as: 'request_line_link'

  # LINE Webhooks
  namespace :webhooks do
    get 'line', to: 'line#index'
    post 'line', to: 'line#create'
  end

  # PWA support (commented out for now)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
end