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

ActiveRecord::Schema[8.0].define(version: 2025_06_09_171000) do
  create_table "books", force: :cascade do |t|
    t.string "title"
    t.string "string"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "commit_comments", force: :cascade do |t|
    t.integer "commit_metadatum_id", null: false
    t.text "content"
    t.text "author"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["commit_metadatum_id"], name: "index_commit_comments_on_commit_metadatum_id"
  end

  create_table "commit_metadata", force: :cascade do |t|
    t.string "sha", null: false
    t.string "repo_owner", null: false
    t.string "repo_name", null: false
    t.string "jira_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["sha", "repo_owner", "repo_name"], name: "index_commit_metadata_on_sha_and_repo_owner_and_repo_name", unique: true
  end

  create_table "jira_tickets", force: :cascade do |t|
    t.string "ticket_number"
    t.integer "commit_metadata_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["commit_metadata_id"], name: "index_jira_tickets_on_commit_metadata_id"
  end

  add_foreign_key "commit_comments", "commit_metadata"
  add_foreign_key "jira_tickets", "commit_metadata", column: "commit_metadata_id"
end
