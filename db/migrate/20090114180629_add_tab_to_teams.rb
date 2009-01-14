class AddTabToTeams < ActiveRecord::Migration
  def self.up
    add_column :teams, :tab_id, :integer
  end

  def self.down
    remove_column :teams, :tab_id
  end
end
