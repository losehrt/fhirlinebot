class CreateLineAccounts < ActiveRecord::Migration[8.0]
  def change
    create_table :line_accounts do |t|
      t.references :user, null: false, foreign_key: true
      t.string :line_user_id
      t.string :access_token
      t.string :refresh_token
      t.datetime :expires_at
      t.string :display_name
      t.string :picture_url

      t.timestamps
    end
    add_index :line_accounts, :line_user_id, unique: true
  end
end
