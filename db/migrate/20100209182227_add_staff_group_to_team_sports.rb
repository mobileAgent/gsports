class AddStaffGroupToTeamSports < ActiveRecord::Migration
  def self.up
    add_column :team_sports, :staff_access_group_id, :integer
  end

  def self.down
    remove_column :team_sports, :staff_access_group_id
  end
end
