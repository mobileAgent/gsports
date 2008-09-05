class AddVideoDateHandling < ActiveRecord::Migration
  def self.up
    add_column :video_assets, :ignore_game_month, :boolean, :default => false
    add_column :video_assets, :game_date_str, :string
  end

  def self.down
    remove_column :video_assets, :ignore_game_month
    remove_column :video_assets, :game_date_str
  end
end
