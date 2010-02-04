class AddUserToRosterEntries < ActiveRecord::Migration
  def self.up
    add_column :roster_entries, :user_id, :integer
  end

  def self.down
    remove_column :roster_entries, :user_id
  end
end
