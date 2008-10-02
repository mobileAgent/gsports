class AddDeltaToLeague < ActiveRecord::Migration
  def self.up
    add_column :leagues, :delta, :boolean, :default => false
  end

  def self.down
    remove_column :leagues, :delta
  end
end
