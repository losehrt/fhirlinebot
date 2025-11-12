class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Use application layout (which includes sidebar, navbar, etc.)
  # layout 'application' is the default, no need to specify

  helper_method :current_user, :logged_in?

  before_action :require_setup_completion, unless: :skip_setup_check?

  private

  # Check if setup is required
  def require_setup_completion
    # Skip check if already on setup page or health check
    return if skip_setup_check?

    # Check if LINE credentials are configured
    unless ApplicationSetting.configured?
      redirect_to setup_path, notice: 'Please configure LINE credentials to continue'
    end
  end

  # Routes that don't require setup to be complete
  def skip_setup_check?
    %w[setup auth rails/health].include?(controller_name) ||
      %w[health_check request_login callback].include?(action_name)
  end

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
