class LineLoginOrganizationHandler
  # 處理 LINE 登入並為使用者分配組織和角色
  # @param user [User] 已認證的使用者
  # @param organization [Organization] 使用者登入的組織
  # @return [UserRole] 建立或更新的使用者角色
  def self.handle_organization_assignment(user, organization)
    # 初始化預設角色
    Role.default_roles

    # 檢查該組織是否有任何使用者
    if organization.has_users?
      # 不是第一個使用者，分配為普通使用者
      role = Role.find_by_name(Role::USER)
    else
      # 是第一個使用者，分配為管理員
      role = Role.find_by_name(Role::ADMIN)
    end

    # 分配角色給使用者
    organization.assign_role(user, role)
  end

  # 檢查使用者是否為第一個登入該組織的使用者
  # @param organization [Organization] 組織
  # @return [Boolean]
  def self.first_user?(organization)
    !organization.has_users?
  end

  # 為使用者提升為管理員
  # @param user [User] 使用者
  # @param organization [Organization] 組織
  # @return [UserRole] 更新的使用者角色
  def self.promote_to_admin(user, organization)
    admin_role = Role.find_by_name(Role::ADMIN)
    organization.assign_role(user, admin_role)
  end

  # 為使用者降級為普通使用者
  # @param user [User] 使用者
  # @param organization [Organization] 組織
  # @return [UserRole] 更新的使用者角色
  def self.demote_to_user(user, organization)
    user_role = Role.find_by_name(Role::USER)
    organization.assign_role(user, user_role)
  end
end
