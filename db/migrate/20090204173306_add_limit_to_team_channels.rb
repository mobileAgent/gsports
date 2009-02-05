class AddLimitToTeamChannels < ActiveRecord::Migration
  def self.up
    add_column :teams, :publish_limit, :integer
  end

  def self.down
    remove_column :teams, :publish_limit
  end
end
