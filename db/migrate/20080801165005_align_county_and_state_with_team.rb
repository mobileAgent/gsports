class AlignCountyAndStateWithTeam < ActiveRecord::Migration
  def self.up
    remove_column :video_assets, :state_id
    remove_column :video_assets, :county_name
    remove_column :teams, :state
    add_column :teams, :county_name, :string
    add_column :teams, :state_id, :integer
  end

  def self.down
    remove_column :teams, :county_name
    remove_column :teams, :state_id
    add_column :teams, :state, :string
    add_column :video_assets, :state_id, :integer
    add_column :video_assets, :county_name, :string
  end
end
