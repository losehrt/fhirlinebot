class CreateUserRoles < ActiveRecord::Migration[8.0]
  def change
    create_table :user_roles do |t|
      t.references :user, null: false, foreign_key: true
      t.references :organization, null: false, foreign_key: true
      t.references :role, null: false, foreign_key: true

      t.timestamps
    end

    # 防止同一用戶在同一組織中有重複的角色
    add_index :user_roles, [:user_id, :organization_id], unique: true, name: 'index_user_roles_on_user_org'
  end
end
