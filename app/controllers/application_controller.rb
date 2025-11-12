class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  helper_method :current_user, :logged_in?

  private

  # Get the currently logged in user
  # @return [User, nil] The logged in user or nil if not authenticated
  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end

  # Check if a user is currently logged in
  # @return [Boolean] true if user is logged in
  def logged_in?
    current_user.present?
  end

  # Log a user in by setting their ID in the session
  # @param user [User] The user to log in
  def login_user(user)
    session[:user_id] = user.id
  end

  # Log the current user out by clearing the session
  def logout_user
    session.delete(:user_id)
    @current_user = nil
  end
end
