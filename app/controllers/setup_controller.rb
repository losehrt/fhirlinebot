class SetupController < ApplicationController
  skip_before_action :require_setup_completion, only: [:index, :update, :validate_credentials]

  # GET /setup - Show setup wizard
  def index
    @setting = ApplicationSetting.current
    @configured = @setting.configured?
  end

  # POST /setup/validate_credentials - Validate LINE credentials via AJAX
  def validate_credentials
    @setting = ApplicationSetting.current

    # Update with provided credentials
    @setting.line_channel_id = params[:line_channel_id]
    @setting.line_channel_secret = params[:line_channel_secret]

    # Validate the credentials
    if @setting.validate_line_credentials!
      render json: {
        success: true,
        message: 'LINE credentials validated successfully!',
        configured: true
      }
    else
      render json: {
        success: false,
        message: @setting.validation_error || 'Failed to validate credentials',
        configured: false
      }, status: :unprocessable_entity
    end
  end

  # POST /setup/update - Save LINE credentials
  def update
    @setting = ApplicationSetting.current

    # Check if credentials are provided
    if params[:line_channel_id].blank? || params[:line_channel_secret].blank?
      flash[:alert] = 'Please provide both Channel ID and Secret'
      redirect_to setup_path and return
    end

    # Update settings
    @setting.line_channel_id = params[:line_channel_id]
    @setting.line_channel_secret = params[:line_channel_secret]

    # Validate before saving
    if @setting.validate_line_credentials!
      flash[:notice] = 'LINE credentials configured successfully! Redirecting to application...'
      redirect_to root_path
    else
      @setting.save # Save with configured = false
      flash[:alert] = "Configuration failed: #{@setting.validation_error}"
      redirect_to setup_path
    end
  end

  # POST /setup/test - Test if current credentials work (for existing config)
  def test
    @setting = ApplicationSetting.current

    unless @setting.configured?
      return render json: {
        success: false,
        message: 'No credentials configured yet'
      }, status: :unprocessable_entity
    end

    if @setting.validate_line_credentials!
      render json: {
        success: true,
        message: 'LINE credentials are valid!',
        last_validated: @setting.last_validated_at
      }
    else
      render json: {
        success: false,
        message: @setting.validation_error || 'Credentials validation failed'
      }, status: :unprocessable_entity
    end
  end

  # DELETE /setup/clear - Clear configuration
  def clear
    @setting = ApplicationSetting.current
    @setting.clear_configuration!

    flash[:notice] = 'Configuration cleared. Please set up again.'
    redirect_to setup_path
  end
end
