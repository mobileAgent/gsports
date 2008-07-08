class AddVideoMetadata < ActiveRecord::Migration
  def self.up
    add_column :video_assets, :home_team_id, :integer
    add_column :video_assets, :visiting_team_id, :integer
    add_column :video_assets, :uploaded_file_path, :string
  end

  def self.down
    remove_column :video_assets, :home_team_id
    remove_column :video_assets, :visiting_team_id
    remove_column :video_assets, :uploaded_file_path
  end
  
end
