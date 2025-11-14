class UserRole < ApplicationRecord
  belongs_to :user
  belongs_to :organization
  belongs_to :role

  validates :user_id, presence: true
  validates :organization_id, presence: true
  validates :role_id, presence: true
  validates :user_id, uniqueness: { scope: :organization_id, message: 'can only have one role per organization' }

  # 取得角色名稱
  # @return [String] 角色名稱
  def role_name
    role.name
  end

  # 取得使用者名稱
  # @return [String] 使用者名稱
  def user_name
    user.name
  end

  # 取得組織名稱
  # @return [String] 組織名稱
  def organization_name
    organization.name
  end
end
