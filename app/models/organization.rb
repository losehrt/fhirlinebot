class Organization < ApplicationRecord
  has_many :line_configurations, dependent: :destroy
  has_many :user_roles, dependent: :destroy
  has_many :users, through: :user_roles
  has_many :roles, through: :user_roles

  validates :name, presence: true

  # 取得該組織的預設 LINE 配置
  # @return [LineConfiguration, nil] 該組織的預設配置，或全局預設
  def line_configuration
    line_configurations.active.default_config.first ||
      LineConfiguration.global_default
  end

  # 列出該組織的所有活躍 LINE 配置
  # @return [ActiveRecord::Relation] 活躍配置列表
  def line_configurations_active
    line_configurations.active
  end

  # 檢查使用者是否為該組織的管理員
  # @param user [User] 使用者物件
  # @return [Boolean]
  def admin?(user)
    user.admin_in_organization?(id)
  end

  # 檢查使用者是否為該組織的版主
  # @param user [User] 使用者物件
  # @return [Boolean]
  def moderator?(user)
    user.moderator_in_organization?(id)
  end

  # 檢查使用者是否為該組織的成員
  # @param user [User] 使用者物件
  # @return [Boolean]
  def has_member?(user)
    users.exists?(user.id)
  end

  # 為使用者分配角色
  # @param user [User] 使用者物件
  # @param role [Role] 角色物件
  # @return [UserRole, nil] 建立的或更新的 UserRole，或 nil
  def assign_role(user, role)
    user_role = user_roles.find_or_initialize_by(user_id: user.id)
    user_role.role = role
    user_role.save
    user_role
  end

  # 檢查組織是否有任何使用者
  # @return [Boolean]
  def has_users?
    users.any?
  end
end
