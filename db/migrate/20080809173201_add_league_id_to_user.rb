class AddLeagueIdToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :league_id, :integer
    execute 'update users u set u.league_id = (select t.league_id from teams t where t.id = u.team_id)'
  end

  def self.down
    remove_column :users, :league_id
  end
end
