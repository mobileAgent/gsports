class AddDeltaToTeam < ActiveRecord::Migration
  def self.up
    add_column :teams, :delta, :boolean, :default => false
  end

  def self.down
    remove_column :teams, :delta
  end
end
