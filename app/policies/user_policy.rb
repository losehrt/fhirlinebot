class UserPolicy < ApplicationPolicy
  def show?
    # 使用者可以看到自己的資料或組織管理員可以看到成員
    user_owns_record? || user_is_admin_of_member_org?
  end

  def update?
    # 使用者可以更新自己的資料或組織管理員可以編輯成員
    user_owns_record? || user_is_admin_of_member_org?
  end

  def edit?
    update?
  end

  def index?
    # 所有登入使用者都可以看到清單
    user.present?
  end

  def manage_roles?
    # 只有系統管理員可以管理角色
    user_is_system_admin?
  end

  def promote_to_admin?
    manage_roles?
  end

  def demote_to_user?
    manage_roles?
  end

  private

  # 檢查使用者是否為該成員所屬組織的管理員
  # @return [Boolean]
  def user_is_admin_of_member_org?
    user&.admin_in_organization?(member_organization_id)
  end

  # 檢查使用者是否為系統管理員
  # @return [Boolean]
  def user_is_system_admin?
    # 如果使用者在任何組織中是管理員，則視為系統管理員
    user&.roles&.any? { |role| role.name == Role::ADMIN }
  end

  # 取得該成員所屬的第一個組織 ID
  # @return [Integer, nil]
  def member_organization_id
    record&.organizations&.first&.id
  end
end
