class CreateApplicationSettings < ActiveRecord::Migration[8.0]
  def change
    create_table :application_settings do |t|
      t.string :line_channel_id
      t.string :line_channel_secret
      t.string :line_channel_secret_encrypted
      t.boolean :configured
      t.datetime :last_validated_at
      t.text :validation_error

      t.timestamps
    end
  end
end
