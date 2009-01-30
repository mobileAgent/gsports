class AddCanPublishToTeams < ActiveRecord::Migration
  def self.up
    add_column :teams, :can_publish, :integer, :limit => 1
  end

  def self.down
    remove_column :teams, :can_publish
  end
end
