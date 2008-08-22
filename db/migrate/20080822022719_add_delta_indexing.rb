class AddDeltaIndexing < ActiveRecord::Migration
  def self.up
    add_column :posts,        :delta, :boolean, :default => false
    add_column :users,        :delta, :boolean, :default => false
    add_column :video_assets, :delta, :boolean, :default => false
    add_column :video_clips,  :delta, :boolean, :default => false
    add_column :video_reels,  :delta, :boolean, :default => false
  end

  def self.down
    remove_column :posts,        :delta
    remove_column :users,        :delta
    remove_column :video_assets, :delta
    remove_column :video_clips,  :delta
    remove_column :video_reels,  :delta
  end
end
