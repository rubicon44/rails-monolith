class CreateAdmins < ActiveRecord::Migration[8.0]
  def change
    create_table :admins do |t|
      t.string :name, null: false
      t.string :login_id, null: false
      t.string :password_digest, null: false

      t.timestamps
    end
    add_index :admins, :login_id, unique: true
  end
end
