class AddVideoAssetsScore < ActiveRecord::Migration
  def self.up
    add_column :video_assets, :home_score, :integer
    add_column :video_assets, :visitor_score, :integer
  end

  def self.down
    remove_column :video_assets, :home_score
    remove_column :video_assets, :visitor_score
  end
end

