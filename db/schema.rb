# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2018_10_14_035243) do

  create_table "mokmoks", force: :cascade do |t|
    t.string "creator_id"
    t.string "title"
    t.text "description"
    t.string "place"
    t.datetime "start_date"
    t.datetime "finish_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "channel_id"
    t.string "team_id"
  end

  create_table "participate_users", force: :cascade do |t|
    t.string "mokmok_id"
    t.string "user_id"
    t.text "comment"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "workspaces", force: :cascade do |t|
    t.string "access_token"
    t.string "scope"
    t.string "team_name"
    t.string "team_id"
    t.string "bot_user_id"
    t.string "bot_access_token"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

end
