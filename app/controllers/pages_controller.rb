class PagesController < ApplicationController
  def home
    # Home page - accessible to both logged in and non-logged in users
  end

  def dashboard
    # Dashboard - only accessible to logged in users
    redirect_to home_path unless logged_in?
  end
end
