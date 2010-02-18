class AddHashToRosterEntry < ActiveRecord::Migration
  def self.up
    add_column :roster_entries, :reg_key, :string
  end

  def self.down
    remove_column :roster_entries, :reg_key
  end
end
