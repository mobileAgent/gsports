class EnsureVideoAssetsHaveLeagueAndTeam < ActiveRecord::Migration
  def self.up
    admin = User.admin.first
    VideoAsset.find(:all, :conditions => "team_id IS NULL or league_id IS NULL").each do |v|
      v.team_id = admin.team_id if v.team_id.nil?
      v.league_id = admin.league_id 
      v.save!
    end
  end

  def self.down
  end
end
