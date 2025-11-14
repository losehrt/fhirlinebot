class LineConfiguration < ApplicationRecord
  belongs_to :organization, optional: true  # 支持全局配置

  # 加密敏感信息
  # 注意：如果要啟用加密，需要在 config/initializers/encryption.rb 中設定密鑰
  # encrypts :channel_secret, deterministic: true

  # 驗證
  validates :channel_id, :channel_secret, :redirect_uri, presence: true
  validates :name, presence: true
  validates :channel_id, uniqueness: true
  validates :is_default, :is_active, inclusion: { in: [true, false] }

  # 回調
  before_save :ensure_single_default_per_organization, if: :is_default_changed?
  after_save :invalidate_line_config_cache
  after_destroy :invalidate_line_config_cache

  # 作用域
  scope :active, -> { where(is_active: true) }
  scope :inactive, -> { where(is_active: false) }
  scope :by_organization, ->(org_id) { where(organization_id: org_id) }
  scope :global, -> { where(organization_id: nil) }
  scope :default_config, -> { where(is_default: true) }

  # 類方法 - 獲取特定組織的配置
  # @param organization_id [Integer, nil] 組織 ID，nil 表示全局配置
  # @return [LineConfiguration, nil] 該組織的預設配置，或 nil
  def self.for_organization(organization_id = nil)
    # 優先查詢特定組織的預設配置
    if organization_id.present?
      by_organization(organization_id)
        .active
        .default_config
        .first
    end || global_default
  end

  # 類方法 - 獲取全局預設配置
  # @return [LineConfiguration, nil] 全局預設配置
  def self.global_default
    global.active.default_config.first
  end

  # 列出特定組織的所有活躍配置
  # @param organization_id [Integer, nil] 組織 ID
  # @return [ActiveRecord::Relation] 活躍配置列表
  def self.active_for_organization(organization_id = nil)
    if organization_id.present?
      by_organization(organization_id).active
    else
      global.active
    end
  end

  # 實例方法 - 標記為預設
  # 自動取消同組織/全局的其他預設配置
  def mark_as_default!
    transaction do
      # 取消同組織的其他預設配置
      LineConfiguration
        .where(organization_id: organization_id)
        .where.not(id: id)
        .update_all(is_default: false)

      # 設置為預設
      update(is_default: true)
    end
  end

  # 實例方法 - 停用配置
  def deactivate!
    update(is_active: false)
  end

  # 實例方法 - 啟用配置
  def activate!
    update(is_active: true)
  end

  # 實例方法 - 記錄最後使用時間
  def touch_last_used!
    update(last_used_at: Time.current)
  end

  # 實例方法 - 是否可以刪除（不是預設配置）
  def can_delete?
    !is_default?
  end

  private

  # 確保每個組織只有一個預設配置
  def ensure_single_default_per_organization
    return unless is_default? && is_default_changed?

    LineConfiguration
      .where(organization_id: organization_id)
      .where.not(id: id)
      .update_all(is_default: false)
  end

  # 使 LineConfig 快取失效
  def invalidate_line_config_cache
    LineConfig.refresh!
  end
end
