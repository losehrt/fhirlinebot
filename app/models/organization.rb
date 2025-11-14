class Organization < ApplicationRecord
  has_many :line_configurations, dependent: :destroy

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
end
