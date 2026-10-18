class CreateEvents < ActiveRecord::Migration[8.0]
  def change
    create_table :events do |t|
      t.references :administrator, null: false, foreign_key: true
      t.string :title, null: false
      t.text :description, null: false
      t.integer :male_capacity, null: false
      t.integer :female_capacity, null: false
      t.datetime :entry_start_at, null: false
      t.datetime :entry_end_at, null: false
      t.datetime :held_start_at, null: false
      t.datetime :held_end_at, null: false
      t.string :status, null: false, default: "scheduled"

      t.timestamps
    end

    add_check_constraint :events, "male_capacity >= 1 AND female_capacity >= 1", name: "events_capacity_positive"
    add_check_constraint :events, "entry_start_at < entry_end_at AND entry_end_at <= held_start_at AND held_start_at < held_end_at", name: "events_periods_in_order"
    add_check_constraint :events, "status IN ('scheduled', 'ready', 'started', 'talk_time', 'result_announced', 'finished')", name: "events_status_valid"
  end
end
