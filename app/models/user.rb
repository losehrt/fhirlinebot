class User < ApplicationRecord
  has_secure_password
  has_one :line_account, dependent: :destroy

  validates :email, presence: true, uniqueness: true,
            format: { with: URI::MailTo::EMAIL_REGEXP, message: 'must be a valid email' }
  validates :name, presence: true
  validates :password, length: { minimum: 8 }, if: -> { password.present? }
  validates :password_confirmation, presence: true, if: -> { password.present? }

  scope :with_line_account, -> { joins(:line_account) }
  scope :without_line_account, -> { left_outer_joins(:line_account).where(line_accounts: { id: nil }) }

  # 取得顯示名稱，優先使用 LINE 暱稱
  def display_name
    line_account&.display_name || name
  end

  # 檢查是否已綁定 LINE 帳號
  def has_line_account?
    line_account.present?
  end

  # 從 LINE 使用者資料建立或更新使用者
  def self.find_or_create_from_line(line_user_id, line_data)
    # 首先嘗試找到已綁定此 LINE 帳號的使用者
    existing_account = LineAccount.find_by(line_user_id: line_user_id)
    if existing_account
      user = existing_account.user
      # 更新已存在的使用者和 LINE 帳號資訊
      user.update(
        name: line_data[:displayName] || user.name
      )
      existing_account.update(
        access_token: line_data[:accessToken],
        refresh_token: line_data[:refreshToken],
        display_name: line_data[:displayName],
        picture_url: line_data[:pictureUrl]
      )
      return user
    end

    # 嘗試找到相同電郵的使用者（假設 LINE 提供電郵）
    line_email = line_data[:email] || "#{line_user_id}@line.example.com"
    user = find_by(email: line_email)

    # 如果找不到則建立新使用者
    unless user
      password = SecureRandom.hex(16)
      user = create!(
        email: line_email,
        name: line_data[:displayName] || 'LINE User',
        password: password,
        password_confirmation: password
      )
    end

    # 更新使用者資訊
    user.update(
      name: line_data[:displayName] || user.name
    )

    # 建立 LINE 帳號（如果還沒有）
    unless user.line_account
      expires_at = if line_data[:expiresIn]
                      (line_data[:expiresIn].to_i).seconds.from_now
                    else
                      30.days.from_now
                    end

      user.create_line_account!(
        line_user_id: line_user_id,
        access_token: line_data[:accessToken] || SecureRandom.hex(32),
        refresh_token: line_data[:refreshToken],
        display_name: line_data[:displayName],
        picture_url: line_data[:pictureUrl],
        expires_at: expires_at
      )
    end

    user
  end
end