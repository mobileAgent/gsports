class EnsureVideoAssetsHaveLeagueAndTeam < ActiveRecord::Migration
  def self.up
    execute 'update video_assets set team_id = (select id from teams limit 1) where team_id is null'
    execute 'update video_assets set league_id = (select id from leagues limit 1) where league_id is null'
  end

  def self.down
  end
end
