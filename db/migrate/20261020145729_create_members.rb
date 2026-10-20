class CreateMembers < ActiveRecord::Migration[8.0]
  def change
    create_table :members do |t|
      t.string :name, null: false
      t.string :email_address, null: false
      t.string :password_digest, null: false
      t.string :gender, null: false

      t.timestamps
    end
    add_index :members, :email_address, unique: true

    add_check_constraint :members, "gender IN ('male', 'female')", name: "members_gender_valid"
  end
end
