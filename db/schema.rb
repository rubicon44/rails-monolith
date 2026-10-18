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

ActiveRecord::Schema[8.0].define(version: 2026_10_18_063855) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "administrators", force: :cascade do |t|
    t.string "name", null: false
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_administrators_on_email_address", unique: true
  end

  create_table "events", force: :cascade do |t|
    t.bigint "administrator_id", null: false
    t.string "title", null: false
    t.text "description", null: false
    t.integer "male_capacity", null: false
    t.integer "female_capacity", null: false
    t.datetime "entry_start_at", null: false
    t.datetime "entry_end_at", null: false
    t.datetime "held_start_at", null: false
    t.datetime "held_end_at", null: false
    t.string "status", default: "scheduled", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["administrator_id"], name: "index_events_on_administrator_id"
    t.check_constraint "entry_start_at < entry_end_at AND entry_end_at <= held_start_at AND held_start_at < held_end_at", name: "events_periods_in_order"
    t.check_constraint "male_capacity >= 1 AND female_capacity >= 1", name: "events_capacity_positive"
    t.check_constraint "status::text = ANY (ARRAY['scheduled'::character varying, 'ready'::character varying, 'started'::character varying, 'talk_time'::character varying, 'result_announced'::character varying, 'finished'::character varying]::text[])", name: "events_status_valid"
  end

  add_foreign_key "events", "administrators"
end
