class AddAccessToGamexUsers < ActiveRecord::Migration
  def self.up
    add_column :gamex_users,  :access_group_id, :integer
  end

  def self.down
    remove_column :gamex_users, :access_group_id
  end
end
