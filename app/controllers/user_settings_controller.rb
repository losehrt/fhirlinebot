class UserSettingsController < ApplicationController
  skip_before_action :require_setup_completion
  before_action :require_login

  def show
    @user = current_user
  end
end
