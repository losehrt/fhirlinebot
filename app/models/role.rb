class Role < ApplicationRecord
  has_many :user_roles, dependent: :destroy
  has_many :users, through: :user_roles

  validates :name, presence: true, uniqueness: { case_sensitive: false }

  # 角色常數
  ADMIN = 'admin'
  MODERATOR = 'moderator'
  USER = 'user'

  # 建立預設角色
  # @return [Array<Role>] 建立或找到的預設角色陣列
  def self.default_roles
    [ADMIN, MODERATOR, USER].map do |role_name|
      find_or_create_by(name: role_name)
    end
  end

  # 按名稱尋找角色
  # @param name [String] 角色名稱
  # @return [Role, nil] 找到的角色或 nil
  def self.find_by_name(name)
    find_by(name: name.downcase)
  end
end
