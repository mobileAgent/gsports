class AddVideoPrivacyFlag < ActiveRecord::Migration
  def self.up
    add_column :video_assets, :public_video, :boolean, :default => true
    add_column :video_clips, :public_video, :boolean, :default => true
    add_column :video_reels, :public_video, :boolean, :default => true
  end

  def self.down
    remove_column :video_assets, :public_video
    remove_column :video_clips, :public_video
    remove_column :video_reels, :public_video
  end
end
