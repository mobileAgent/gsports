class AddRosterRecipients < ActiveRecord::Migration
  def self.up
    add_column :message_threads, :to_roster_entry_ids, :string
    add_column :message_threads, :is_sms, :boolean, :default => 0
    
    execute 'update message_threads set is_sms=0 where is_sms is null'
  end

  def self.down
    remove_column :message_threads, :to_roster_entry_ids
    remove_column :message_threads, :is_sms
  end
end
