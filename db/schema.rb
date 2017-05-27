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

ActiveRecord::Schema.define(version: 20170526020631) do

  create_table "fleet_logs", force: :cascade do |t|
    t.integer "fleet_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "log_filename"
    t.index ["fleet_id"], name: "index_fleet_logs_on_fleet_id"
  end

  create_table "fleet_rankings", force: :cascade do |t|
    t.integer "fleet_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "score"
    t.index ["fleet_id"], name: "index_fleet_rankings_on_fleet_id"
  end

  create_table "fleets", force: :cascade do |t|
    t.integer "fleet_id"
    t.integer "fleet_log_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "filename"
    t.string "name"
    t.index ["fleet_id"], name: "index_fleets_on_fleet_id"
    t.index ["fleet_log_id"], name: "index_fleets_on_fleet_log_id"
  end

  create_table "fleets_games", id: false, force: :cascade do |t|
    t.integer "game_id"
    t.integer "fleet_id"
    t.index ["fleet_id"], name: "index_fleets_games_on_fleet_id"
    t.index ["game_id"], name: "index_fleets_games_on_game_id"
  end

  create_table "fleets_leagues", id: false, force: :cascade do |t|
    t.integer "league_id"
    t.integer "fleet_id"
    t.index ["fleet_id"], name: "index_fleets_leagues_on_fleet_id"
    t.index ["league_id"], name: "index_fleets_leagues_on_league_id"
  end

  create_table "games", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "journal_filename"
  end

  create_table "games_users", id: false, force: :cascade do |t|
    t.integer "user_id"
    t.integer "game_id"
    t.index ["game_id"], name: "index_games_users_on_game_id"
    t.index ["user_id"], name: "index_games_users_on_user_id"
  end

  create_table "leagues", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
  end

  create_table "leagues_users", id: false, force: :cascade do |t|
    t.integer "user_id"
    t.integer "league_id"
    t.index ["league_id"], name: "index_leagues_users_on_league_id"
    t.index ["user_id"], name: "index_leagues_users_on_user_id"
  end

  create_table "missions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
    t.string "filename"
  end

  create_table "tournaments", force: :cascade do |t|
    t.integer "league_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["league_id"], name: "index_tournaments_on_league_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

end
