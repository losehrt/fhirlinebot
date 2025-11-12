class LineAccount < ApplicationRecord
  belongs_to :user

  validates :user_id, presence: true
  validates :line_user_id, presence: true, uniqueness: true
  validates :access_token, presence: true, on: :create

  # 檢查 access token 是否已過期或即將過期（1小時內）
  def access_token_expired?
    return true if expires_at.blank?
    expires_at <= 1.hour.from_now
  end

  # 取得要顯示的名稱
  def profile_name
    display_name.presence || user&.name
  end

  # 檢查是否需要刷新令牌
  def should_refresh_token?
    access_token_expired?
  end

  # 刷新令牌
  def refresh_token!(new_access_token, new_expires_at)
    self.access_token = new_access_token
    self.expires_at = new_expires_at
    save!
    true
  end

  # 使令牌失效
  def invalidate!
    self.access_token = nil
    self.refresh_token = nil
    self.expires_at = Time.current
    save!
  end
end