class AddResponseModeToLineConfigurations < ActiveRecord::Migration[8.0]
  def change
    add_column :line_configurations, :response_mode, :string, default: 'flex', comment: "Response mode for text messages (flex, text, quickreply, etc.)"
  end
end
