class AddVideoFilmedBy < ActiveRecord::Migration
  def self.up
    add_column :video_assets, :filmed_by_name, :string, :limit => 100
    add_column :video_assets, :filmed_by, :integer, :limit => 11 
    add_column :video_assets, :announcer_name, :string, :limit => 100
    add_column :video_assets, :announcer, :integer, :limit => 11 
  end

  def self.down
    remove_column :video_assets, :filmed_by_name
    remove_column :video_assets, :filmed_by
    remove_column :video_assets, :announcer_name
    remove_column :video_assets, :announcer
  end
end
