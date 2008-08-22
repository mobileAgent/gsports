class AddDeltaToModels < ActiveRecord::Migration
  def self.up
    add_column :video_assets, :delta, :boolean
    add_column :video_reels, :delta, :boolean
    add_column :video_clips, :delta, :boolean        
    add_column :posts, :delta, :boolean
    add_column :users, :delta, :boolean    
  end

  def self.down
    remove_column :video_assets, :delta
    remove_column :video_reels, :delta
    remove_column :video_clips, :delta        
    remove_column :posts, :delta
    remove_column :users, :delta
  end
end
