class VideoAudioAndNotesField < ActiveRecord::Migration
  def self.up
    add_column :video_assets, :internal_notes, :text
    add_column :video_assets, :missing_audio, :boolean, :default => false
  end

  def self.down
    remove_column :video_assets, :no_audio
    remove_column :video_assets, :internal_notes
  end
end
