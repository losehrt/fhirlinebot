class CreateLineConfigurations < ActiveRecord::Migration[8.0]
  def change
    create_table :line_configurations do |t|
      t.references :organization, null: true, foreign_key: true  # 支持全局配置（organization_id = nil）
      t.string :name, null: false                                 # 配置名稱（如 "主院所", "備用"）
      t.string :channel_id, null: false                           # LINE Channel ID
      t.string :channel_secret, null: false                       # LINE Channel Secret
      t.string :redirect_uri, null: false                         # LINE Login Redirect URI
      t.boolean :is_default, default: false                       # 是否為預設配置
      t.boolean :is_active, default: true                         # 是否啟用
      t.datetime :last_used_at                                    # 最後使用時間
      t.text :description                                         # 描述/備註

      t.timestamps
    end

    # 索引（t.references 已自動建立 :organization_id 索引）
    add_index :line_configurations, [:organization_id, :is_default], unique: true, where: "is_default = true"
    add_index :line_configurations, [:organization_id, :is_active]
    add_index :line_configurations, :channel_id, unique: true
  end
end
