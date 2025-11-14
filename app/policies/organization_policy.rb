class OrganizationPolicy < ApplicationPolicy
  def show?
    member?
  end

  def edit?
    admin?
  end

  def update?
    admin?
  end

  def destroy?
    admin?
  end

  def index?
    # 所有登入使用者都可以看到自己所屬的組織清單
    user.present?
  end

  def manage_members?
    admin?
  end

  def manage_roles?
    admin?
  end

  private

  def organization_id
    record.id
  end
end
