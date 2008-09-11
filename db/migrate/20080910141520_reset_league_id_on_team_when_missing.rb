class ResetLeagueIdOnTeamWhenMissing < ActiveRecord::Migration
  def self.up
    execute 'update teams set league_id = 1 where league_id is null'
  end

  def self.down
  end
end
