class AddAccessTokenToLineConfigurations < ActiveRecord::Migration[8.0]
  def change
    add_column :line_configurations, :access_token, :string
  end
end
