class CreateGamex < ActiveRecord::Migration
  
  def self.up
        
    create_table :gamex_users do |t|
      t.integer :user_id
      t.integer :league_id
    end
    
    create_table :gamex_leagues do |t|
      t.integer :league_id
    end

    create_table :video_reel_sources do |t|
      t.integer :video_reel_id
      t.integer :video_clip_id
    end
    
    create_table :video_histories do |t|
      t.integer :user_id
      t.integer :school_id
      t.integer :video_id
      t.string  :game_title
      t.string  :game_date
      t.string  :activity_type, :size=>2
      t.timestamp :activity_date      
    end
    
    add_column :video_assets,  :gamex_league_id, :integer
    #add_column :video_clips,  :gamex_league_id, :integer

  end

  def self.down
    drop_table :gamex_users
    drop_table :gamex_leagues
    drop_table :video_reel_sources
    drop_table :video_histories
    
    remove_column :video_assets, :gamex_league_id
    #remove_column :video_clips, :gamex_league_id
  end
  
end
