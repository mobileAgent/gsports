class CreateDeletedVideos < ActiveRecord::Migration
  def self.up
    create_table :deleted_videos do |t|
      t.integer :video_id, :null => false
      t.string :dockey, :null => false
      t.string :title
      t.integer :deleted_by
      t.string :video_type
      t.timestamp :deleted_at
    end
  end

  def self.down
    drop_table :deleted_videos
  end
end
