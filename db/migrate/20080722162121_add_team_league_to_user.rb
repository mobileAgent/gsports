class AddTeamLeagueToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :team_id, :integer
    team = Team.find(:first)
    User.find(:all).each do |u|
      u.team= team
      u.save!
    end
  end

  def self.down
    remove_column :users, :team_id
  end
end
