class CreateVideoClips < ActiveRecord::Migration
  def self.up
    create_table :video_clips do |t|
      t.string :title
      t.string :description
      t.string :length
      t.string :dockey
      t.string :view_url
      t.integer :video_asset_id
      t.integer :user_id

      t.timestamps
    end
  end

  def self.down
    drop_table :video_clips
  end
end
