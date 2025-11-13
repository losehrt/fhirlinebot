class PagesController < ApplicationController
  # Flexy layout is inherited from ApplicationController
  skip_before_action :require_setup_completion, only: [:home]

  def home
    # Home page - accessible to both logged in and non-logged in users
  end

  def profile
    # User profile page
    redirect_to root_path unless logged_in?
  end
end
