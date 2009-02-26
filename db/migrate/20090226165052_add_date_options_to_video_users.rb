class AddDateOptionsToVideoUsers < ActiveRecord::Migration
  def self.up
    add_column :video_users, :ignore_game_day, :boolean, :default => false
    add_column :video_users, :ignore_game_month, :boolean, :default => false
    add_column :video_users, :game_date_str, :string
    
    #rename field
    remove_column :video_users, :video_date
    add_column :video_users, :game_date, :datetime
    
    add_column :video_users, :missing_audio, :boolean, :default => false
    add_column :video_users, :gsan, :string
    add_column :video_users, :internal_notes, :text
  end

  def self.down
    remove_column :video_users, :ignore_game_day
    remove_column :video_users, :ignore_game_month
    remove_column :video_users, :game_date_str
    
    remove_column :video_users, :game_date
    add_column :video_users, :video_date, :timestamp
  
    remove_column :video_users, :missing_audio
    remove_column :video_users, :gsan
    remove_column :video_users, :internal_notes
  end  
end
