class UsersController < ApplicationController
  skip_before_action :require_setup_completion
  before_action :require_login
  before_action :set_user, only: [:disconnect_line_account]

  # Disconnect LINE account from current user
  def disconnect_line_account
    unless @user.has_line_account?
      return render json: { error: 'User does not have a LINE account' }, status: :unprocessable_entity
    end

    @user.line_account.destroy
    redirect_to user_settings_path, notice: 'LINE account has been disconnected successfully.'
  end

  # Show page to link LINE account
  def link_line_account
    # If user already has LINE account, redirect to settings
    if current_user.has_line_account?
      redirect_to user_settings_path, notice: 'You already have a LINE account linked.'
      return
    end
  end

  # Request to link LINE account
  def request_line_link
    # If user already has LINE account, return error
    if current_user.has_line_account?
      return render json: { error: 'User already has a LINE account' }, status: :bad_request
    end

    # Set intent in session to link account on callback
    session[:line_link_intent] = 'link_account'

    # Create authorization request
    handler = LineLoginHandler.new
    auth_request = handler.create_authorization_request(callback_url)

    session[:line_login_state] = auth_request[:state]
    session[:line_login_nonce] = auth_request[:nonce]

    if request.format.json?
      render json: { authorization_url: auth_request[:authorization_url] }
    else
      redirect_to auth_request[:authorization_url], allow_other_host: true
    end
  end

  private

  def set_user
    @user = current_user
  end

  def callback_url
    auth_line_callback_url
  end
end
