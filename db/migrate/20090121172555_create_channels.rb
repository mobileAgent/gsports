class CreateChannels < ActiveRecord::Migration
  
  def self.up
    
    create_table :channels do |t|
      t.string   :name,       :limit => 30
      t.integer  "layout",    :limit => 3
      t.integer  "team_id",   :limit => 11
      t.integer  "league_id", :limit => 11
    end
    
    create_table :channel_videos do |t|
      t.string   "video_type"
      t.integer  "video_id", :limit => 11
      t.integer  "channel_id", :limit => 11
    end
    
  end

  def self.down
    drop_table :channel_videos
    drop_table :channels
  end
  
end
