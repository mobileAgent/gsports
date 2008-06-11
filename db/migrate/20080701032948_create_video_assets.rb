class CreateVideoAssets < ActiveRecord::Migration
  def self.up
    create_table :video_assets do |t|
      t.string :dockey
      t.string :title
      t.string :description
      t.string :author_name
      t.string :author_email
      t.string :video_length
      t.string :frame_rate
      t.string :video_type
      t.string :video_status
      t.boolean :can_edit
      t.string :thumbnail
      t.string :thumbnail_low
      t.string :thumbnail_medium
      t.integer :league_id
      t.integer :team_id
      t.integer :user_id
      t.string :sport
      t.timestamp :game_date
      t.timestamps
    end
  end

  def self.down
    drop_table :video_assets
  end
end
