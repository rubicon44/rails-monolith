class CreateNotifications < ActiveRecord::Migration[8.0]
  def change
    create_table :notifications do |t|
      t.references :member, null: false, foreign_key: true, index: false
      t.string :title, null: false
      t.text :body, null: false

      t.timestamps
    end
  end
end
