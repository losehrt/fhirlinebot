class ChangeLineMessageTimestampToBigint < ActiveRecord::Migration[8.0]
  def change
    change_column :line_messages, :timestamp, :bigint
  end
end
