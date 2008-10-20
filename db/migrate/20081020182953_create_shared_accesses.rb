class CreateSharedAccesses < ActiveRecord::Migration
  def self.up
    create_table :shared_accesses do |t|
      t.string      :key, :limit => 20
      t.string      :item_type, :null => false
      t.integer     :item_id, :limit => 11, :null => false
      t.timestamps
    end
    add_index :shared_accesses, :key, :unique => true

    add_column :video_assets, :shared_access_id, :integer, :limit => 11
    add_column :video_clips, :shared_access_id, :integer, :limit => 11
    add_column :video_reels, :shared_access_id, :integer, :limit => 11
    add_column :messages, :shared_access_id, :integer, :limit => 11
    add_column :sent_messages, :shared_access_id, :integer, :limit => 11

  end

  def self.down
    remove_column :video_assets, :shared_access_id
    remove_column :video_clips, :shared_access_id
    remove_column :video_reels, :shared_access_id
    remove_column :messages, :shared_access_id
    remove_column :sent_messages, :shared_access_id
    drop_table :shared_accesses
  end
end
