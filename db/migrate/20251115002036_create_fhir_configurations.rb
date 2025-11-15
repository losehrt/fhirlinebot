class CreateFhirConfigurations < ActiveRecord::Migration[8.0]
  def change
    create_table :fhir_configurations do |t|
      t.references :organization, null: false, foreign_key: true
      t.string :server_url, null: false, comment: 'FHIR server base URL'
      t.text :description, comment: 'Configuration description'
      t.boolean :is_active, default: true, null: false, comment: 'Whether this configuration is active'
      t.datetime :last_validated_at, comment: 'Last successful validation timestamp'

      t.timestamps
    end

    # t.references already creates the organization_id index
    add_index :fhir_configurations, [:organization_id, :is_active]
  end
end
