class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index?
    false
  end

  def show?
    false
  end

  def create?
    false
  end

  def new?
    create?
  end

  def update?
    false
  end

  def edit?
    update?
  end

  def destroy?
    false
  end

  # 檢查使用者是否為系統管理員
  # @return [Boolean]
  def admin?
    user&.admin_in_organization?(organization_id)
  end

  # 檢查使用者是否為版主
  # @return [Boolean]
  def moderator?
    user&.moderator_in_organization?(organization_id)
  end

  # 檢查使用者是否為組織成員
  # @return [Boolean]
  def member?
    user&.member_of_organization?(organization_id)
  end

  # 取得當前組織 ID
  # 子類應該覆蓋此方法以返回適當的 organization_id
  # @return [Integer, nil]
  def organization_id
    nil
  end

  # 檢查使用者是否可以存取此記錄
  # @return [Boolean]
  def user_owns_record?
    # 如果記錄本身是 User，則檢查是否為同一使用者
    if record.is_a?(User)
      record == user
    # 否則，檢查記錄是否有 user 關聯
    elsif record.respond_to?(:user)
      record.user == user
    else
      false
    end
  end
end
