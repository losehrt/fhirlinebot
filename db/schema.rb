# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_11_14_134418) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "application_settings", force: :cascade do |t|
    t.string "line_channel_id"
    t.string "line_channel_secret"
    t.string "line_channel_secret_encrypted"
    t.boolean "configured"
    t.datetime "last_validated_at"
    t.text "validation_error"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "line_accounts", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "line_user_id"
    t.string "access_token"
    t.string "refresh_token"
    t.datetime "expires_at"
    t.string "display_name"
    t.string "picture_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["line_user_id"], name: "index_line_accounts_on_line_user_id", unique: true
    t.index ["user_id"], name: "index_line_accounts_on_user_id"
  end

  create_table "line_configurations", force: :cascade do |t|
    t.bigint "organization_id"
    t.string "name", null: false
    t.string "channel_id", null: false
    t.string "channel_secret", null: false
    t.string "redirect_uri", null: false
    t.boolean "is_default", default: false
    t.boolean "is_active", default: true
    t.datetime "last_used_at"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "access_token"
    t.index ["channel_id"], name: "index_line_configurations_on_channel_id", unique: true
    t.index ["organization_id", "is_active"], name: "index_line_configurations_on_organization_id_and_is_active"
    t.index ["organization_id", "is_default"], name: "index_line_configurations_on_organization_id_and_is_default", unique: true, where: "(is_default = true)"
    t.index ["organization_id"], name: "index_line_configurations_on_organization_id"
  end

  create_table "line_messages", force: :cascade do |t|
    t.string "line_user_id"
    t.string "message_type"
    t.text "content"
    t.string "line_message_id"
    t.bigint "timestamp"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "line_postbacks", force: :cascade do |t|
    t.string "line_user_id"
    t.string "data"
    t.json "params"
    t.integer "timestamp"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "organizations", force: :cascade do |t|
    t.string "name"
    t.string "slug"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "roles", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_roles_on_name", unique: true
  end

  create_table "user_roles", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "organization_id", null: false
    t.bigint "role_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id"], name: "index_user_roles_on_organization_id"
    t.index ["role_id"], name: "index_user_roles_on_role_id"
    t.index ["user_id", "organization_id"], name: "index_user_roles_on_user_org", unique: true
    t.index ["user_id"], name: "index_user_roles_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email"
    t.string "name"
    t.string "password_digest"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "line_accounts", "users"
  add_foreign_key "line_configurations", "organizations"
  add_foreign_key "user_roles", "organizations"
  add_foreign_key "user_roles", "roles"
  add_foreign_key "user_roles", "users"
end
