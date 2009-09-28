class AddGamexReleaseOverrideToVideoAssets < ActiveRecord::Migration
  def self.up
    add_column :video_assets, :gamex_release_override, :boolean
  end

  def self.down
    remove_column :video_assets, :gamex_release_override
  end
end
