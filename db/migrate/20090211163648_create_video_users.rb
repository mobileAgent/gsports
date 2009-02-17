class CreateVideoUsers < ActiveRecord::Migration
  def self.up
    create_table :video_users do |t|
      
      t.integer   :user_id
      
      t.string    :title
      t.string    :description
      t.timestamp :video_date
      
      t.integer   :view_count, :limit => 11, :default => 0
      t.boolean   :public_video, :default => true
        
      t.boolean   :delta, :default => false
      t.integer   :shared_access_id, :limit => 11
              
      t.string    :dockey
      t.string    :video_length
      t.string    :video_type
      t.string    :video_status
      
      t.timestamps
    end
  end

  def self.down
    drop_table :video_users
  end
end
