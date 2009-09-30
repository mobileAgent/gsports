class UpdateVideoHistories < ActiveRecord::Migration
  def self.up

    drop_table :video_histories

    create_table :video_histories do |t|
      t.integer :user_id
      t.integer :team_id
      t.integer :video_asset_id
      t.string  :activity_type, :limit=>1

      t.timestamps
    end

  end

  def self.down

    drop_table :video_histories

    create_table :video_histories do |t|
      t.integer :user_id
      t.integer :school_id
      t.integer :video_id
      t.string  :game_title
      t.string  :game_date
      t.string  :activity_type, :size=>2
      t.timestamp :activity_date
    end

  end
end

