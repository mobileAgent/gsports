class AddReadyDateToVideoAssets < ActiveRecord::Migration
  def self.up
    add_column :video_assets, :ready_at, :datetime
  end

  def self.down
    remove_column :video_assets, :ready_at
  end
end
