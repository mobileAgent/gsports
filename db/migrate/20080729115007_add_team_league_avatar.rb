class AddTeamLeagueAvatar < ActiveRecord::Migration
  def self.up
    remove_column :teams, :logo_uri
    remove_column :leagues, :logo_uri
    add_column :teams, :avatar_id, :integer
    add_column :leagues, :avatar_id, :integer
  end

  def self.down
    remove_column :teams, :avatar_id
    remove_column :leagues, :avatar_id
    add_column :teams, :logo_uri, :string
    add_column :leagues, :logo_uri, :string
  end
end
