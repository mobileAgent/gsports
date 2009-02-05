class AddChannelsToLeagues < ActiveRecord::Migration
  def self.up
    add_column :leagues, :can_publish, :integer, :limit => 1
    add_column :leagues, :publish_limit, :integer
  end

  def self.down
    remove_column :leagues, :can_publish
    remove_column :leagues, :publish_limit
  end
end
