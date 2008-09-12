class RepairVideosWithBadTeamIds < ActiveRecord::Migration
  def self.up
    ["team_id","home_team_id","visiting_team_id"].each do |field|
      execute "update video_assets v set v.#{field} = 1 where v.#{field} is not null and (select count(1) from teams t where t.id = v.#{field}) = 0"
    end
  end

  def self.down
    # there is no down for this migration
  end
end
