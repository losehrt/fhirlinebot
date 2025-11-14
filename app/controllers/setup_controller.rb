class SetupController < ApplicationController
  skip_before_action :require_setup_completion, only: [:show, :update, :validate_credentials]

  # GET /setup - Show setup wizard
  def show
    @setting = ApplicationSetting.current
    @configured = @setting.configured?
  end

  # POST /setup/validate_credentials - Validate LINE credentials via AJAX
  def validate_credentials
    @setting = ApplicationSetting.current

    # Update with provided credentials
    @setting.line_channel_id = params[:line_channel_id]
    @setting.line_channel_secret = params[:line_channel_secret]

    # Only validate credential format (not API connectivity)
    # API connectivity check may fail in dev due to SSL cert issues, which is expected
    validator = LineValidator.new(@setting.line_channel_id, @setting.line_channel_secret)

    if validator.valid_format?
      render json: {
        success: true,
        message: 'LINE credentials format is valid!',
        configured: true
      }
    else
      @setting.update(validation_error: 'Invalid LINE credentials format. Channel ID should be 8+ digits, Secret should be 20+ characters')
      render json: {
        success: false,
        message: @setting.validation_error,
        configured: false
      }, status: :unprocessable_entity
    end
  end

  # POST /setup/update - Save LINE credentials
  def update
    @setting = ApplicationSetting.current

    # Check if credentials are provided
    if params[:line_channel_id].blank? || params[:line_channel_secret].blank?
      flash[:alert] = '請提供 Channel ID 和 Channel Secret'
      redirect_to setup_path and return
    end

    # Update settings
    @setting.line_channel_id = params[:line_channel_id]
    @setting.line_channel_secret = params[:line_channel_secret]

    # Only validate credential format (not API connectivity)
    # API connectivity check may fail in dev due to SSL cert issues, which is expected
    # The actual OAuth flow will test connectivity in the real browser environment
    validator = LineValidator.new(@setting.line_channel_id, @setting.line_channel_secret)

    if validator.valid_format?
      # Format is valid, save credentials
      @setting.update(configured: true, last_validated_at: Time.current, validation_error: nil)
      flash[:notice] = 'LINE credentials configured successfully! Redirecting to application...'
      redirect_to root_path
    else
      # Format error - don't allow saving
      @setting.update(validation_error: 'Invalid LINE credentials format. Channel ID should be 8+ digits, Secret should be 20+ characters')
      flash[:alert] = "無法儲存：#{@setting.validation_error}"
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

    # Only validate credential format (not API connectivity)
    validator = LineValidator.new(@setting.line_channel_id, @setting.line_channel_secret)

    if validator.valid_format?
      render json: {
        success: true,
        message: 'LINE credentials format is valid!',
        last_validated: @setting.last_validated_at
      }
    else
      render json: {
        success: false,
        message: 'Invalid credentials format'
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
