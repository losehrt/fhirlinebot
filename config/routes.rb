Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Setup routes (initial configuration)
  get "/setup", to: "setup#index", as: :setup
  post "/setup/validate", to: "setup#validate_credentials", as: :validate_line_credentials
  post "/setup/update", to: "setup#update", as: :update_setup
  post "/setup/test", to: "setup#test", as: :test_setup
  delete "/setup/clear", to: "setup#clear", as: :clear_setup

  # Authentication routes
  post "auth/request_login", to: "auth#request_login", as: :request_line_login
  get "auth/line/callback", to: "auth#callback", as: :line_callback
  post "auth/logout", to: "auth#logout", as: :logout

  # Pages routes
  get "/", to: "pages#home", as: :home
  root "pages#home"
  get "/dashboard", to: "pages#dashboard", as: :dashboard
  get "/profile", to: "pages#profile", as: :profile

  # UI Demo route
  get "/ui-demo", to: "ui_demo#index", as: :ui_demo

  # Healthicons Demo route
  get "/healthicons", to: "healthicons_demo#index", as: :healthicons_demo

  # Dashboard route (using new controller)
  get "/dashboard", to: "dashboard#index", as: :dashboard_new
end
