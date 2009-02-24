class AddStaffLimitToTeamLeague < ActiveRecord::Migration
  def self.up
    add_column :teams, :staff_limit, :integer
    add_column :leagues, :staff_limit, :integer
  end

  def self.down
    remove_column :teams, :staff_limit
    remove_column :leagues, :staff_limit
  end
end
