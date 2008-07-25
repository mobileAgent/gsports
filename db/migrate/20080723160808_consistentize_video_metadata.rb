class ConsistentizeVideoMetadata < ActiveRecord::Migration
  def self.up
    add_column :video_assets, :county_name, :string
    add_column :video_assets, :game_level, :string
    add_column :video_assets, :game_gender, :string
    add_column :video_assets, :state_id, :integer
    add_column :video_assets, :view_count, :integer, :default => 0
    
    remove_column :video_assets, :thumbnail
    remove_column :video_assets, :thumbnail_low
    remove_column :video_assets, :thumbnail_medium
    remove_column :video_assets, :can_edit
    remove_column :video_assets, :author_name
    remove_column :video_assets, :author_email
    remove_column :video_assets, :frame_rate
    
    add_column :video_reels, :video_length, :string
    add_column :video_reels, :thumbnail_dockey, :string
    add_column :video_reels, :view_count, :integer, :default => 0

    rename_column :video_clips, :length, :video_length
    remove_column :video_clips, :view_url
    add_column :video_clips, :view_count, :integer, :default => 0

    add_column :leagues, :state_id, :integer
    remove_column :leagues, :state
  end

  def self.down
    remove_column :video_assets, :county_name
    remove_column :video_assets, :game_level
    remove_column :video_assets, :game_gender
    remove_column :video_assets, :state_id
    remove_column :video_assets, :view_count
    add_column :video_assets, :thumbnail, :string
    add_column :video_assets, :thumbnail_low, :string
    add_column :video_assets, :thumbnail_medium, :string
    add_column :video_assets, :can_edit, :boolean
    add_column :video_assets, :author_name, :string
    add_column :video_assets, :author_email, :string
    add_column :video_assets, :frame_rate, :string
    
    remove_column :video_reels, :video_length
    remove_column :video_reels, :thumbnail_dockey
    remove_column :video_reels, :view_count
    
    rename_column :video_clips, :video_length, :length
    add_column :video_clips, :view_url, :string
    remove_column :video_clips, :view_count

    add_column :leagues, :state, :string
    remove_column :leagues, :state_id
  end
end
