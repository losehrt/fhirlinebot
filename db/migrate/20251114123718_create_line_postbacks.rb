class CreateLinePostbacks < ActiveRecord::Migration[8.0]
  def change
    create_table :line_postbacks do |t|
      t.string :line_user_id
      t.string :data
      t.json :params
      t.integer :timestamp

      t.timestamps
    end
  end
end
