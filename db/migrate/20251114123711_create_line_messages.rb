class CreateLineMessages < ActiveRecord::Migration[8.0]
  def change
    create_table :line_messages do |t|
      t.string :line_user_id
      t.string :message_type
      t.text :content
      t.string :line_message_id
      t.integer :timestamp

      t.timestamps
    end
  end
end
