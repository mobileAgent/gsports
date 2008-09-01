class AddVideoGsanAndGameType < ActiveRecord::Migration
  def self.up
    add_column :video_assets, :game_type, :string
    add_column :video_assets, :gsan, :string
    add_column :video_assets, :ignore_game_day, :boolean, :default => false
  end

  def self.down
    remove_column :video_assets, :game_type
    remove_column :video_assets, :gsan
    remove_column :video_assets, :ignore_game_day
  end
end
