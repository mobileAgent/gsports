class AddAvatarToTeamSports < ActiveRecord::Migration
  def self.up
    add_column :team_sports, :avatar_id, :integer
  end

  def self.down
    remove_column :team_sports, :avatar_id
  end
end
