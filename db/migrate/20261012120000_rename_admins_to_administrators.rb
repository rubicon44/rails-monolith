class RenameAdminsToAdministrators < ActiveRecord::Migration[8.0]
  def change
    rename_table :admins, :administrators
    rename_column :administrators, :login_id, :email_address
  end
end
