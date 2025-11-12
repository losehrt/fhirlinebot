class UiDemoController < ApplicationController
  skip_before_action :require_setup_completion  # Allow access without setup

  def index
  end
end
