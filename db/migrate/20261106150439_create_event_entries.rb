class CreateEventEntries < ActiveRecord::Migration[8.0]
  def change
    create_table :event_entries do |t|
      t.references :event, null: false, foreign_key: true, index: false
      t.references :member, null: false, foreign_key: true, index: false
      t.string :status, null: false, default: "pending"

      t.timestamps
    end

    add_index :event_entries, [ :event_id, :member_id ], unique: true
    add_check_constraint :event_entries, "status IN ('pending', 'approved')", name: "event_entries_status_valid"
  end
end
