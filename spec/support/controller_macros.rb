module ControllerMacros
  def login_user(user = nil)
    @request.env["devise.mapping"] = Devise.mappings[:user]
    user ||= FactoryBot.create(:user)
    sign_in user
    user
  end

  def login_line_user(user = nil)
    user ||= FactoryBot.create(:user, :line_user)
    login_user(user)
    user
  end
end