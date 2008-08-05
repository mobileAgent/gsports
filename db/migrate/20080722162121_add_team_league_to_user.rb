class AddTeamLeagueToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :team_id, :integer
    execute 'update users set team_id = (select id from teams order by id limit 1)'
  end

  def self.down
    remove_column :users, :team_id
  end
end
