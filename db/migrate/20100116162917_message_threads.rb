class MessageThreads < ActiveRecord::Migration
  def self.up
    rename_table :messages, :messages_obsolete    
    rename_table :sent_messages, :sent_messages_obsolete

    create_table :message_threads do |t|
      t.string   :title,    :limit => 250, :null => false
      t.integer  :from_id,  :limit => 11, :null => false
      t.datetime :created_at
      t.string   :to_ids
      t.text     :to_emails
      t.text     :to_phones
      t.string   :to_access_group_ids
    end
    
#    create_table :message_thread_recipients do |t|
#      t.integer  :thread_id,            :limit => 11, :null => false
#      t.integer  :to_id,                :limit => 11
#      t.integer  :to_access_group_id,   :limit => 11
#      t.integer  :to_email,             :limit => 256
#      t.integer  :to_sms,               :limit => 20
#    end
    
    create_table :sent_messages do |t|
      t.integer  :thread_id,        :limit => 11, :null => false
      t.integer  :from_id,          :limit => 11, :null => false
      t.text     :body
      t.datetime :created_at 
      t.integer  :shared_access_id, :limit => 11
      t.boolean  :owner_deleted,    :default => false
    end
    
    create_table :messages do |t|
      t.integer  :thread_id,         :limit => 11, :null => false
      t.integer  :sent_message_id,  :limit => 11, :null => false
      t.integer  :to_id,             :limit => 11, :null => false
      t.datetime :created_at
      t.boolean  :read,              :default => false
      t.boolean  :deleted,           :default => false
    end
    
    #add_index :message_thread_recipients, :thread_id
    
    add_index :sent_messages, :thread_id
    add_index :sent_messages, :from_id
    
    add_index :messages, :thread_id
    add_index :messages, :sent_message_id
    add_index :messages, :to_id
    
  end

  def self.down
    
    #remove_index :message_thread_recipients, :thread_id
    
    remove_index :sent_messages, :thread_id
    remove_index :sent_messages, :from_id
    
    remove_index :messages, :thread_id
    remove_index :messages, :sent_message_id
    remove_index :messages, :to_id
    
    drop_table :messages
    drop_table :sent_messages
    #drop_table :message_thread_recipients
    drop_table :message_threads
    
    rename_table :messages_obsolete, :messages
    rename_table :sent_messages_obsolete, :sent_messages
    
  end
end
