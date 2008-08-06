class AddAdZoneToTeam < ActiveRecord::Migration
  def self.up
    add_column :teams, :ad_zone, :integer, :default => 1
    execute 'update teams set ad_zone = 1 where ad_zone is null'
  end

  def self.down
    remove_column :teams, :ad_zone
  end
end
