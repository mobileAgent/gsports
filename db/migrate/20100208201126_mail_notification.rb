class MailNotification < ActiveRecord::Migration
  def self.up
    add_column :sent_messages, :sms_notify, :boolean , :default => 0
    add_column :users, :notify_message_email, :boolean, :default => 1
    add_column :users, :notify_message_sms, :boolean, :default => 1
    
    execute 'update sent_messages set sms_notify=0 where sms_notify is null'
    execute 'update users set notify_message_email=1 where notify_message_email is null'
    execute 'update users set notify_message_sms=1 where notify_message_sms is null'
  end

  def self.down
    remove_column :sent_messages, :sms_notify
    remove_column :users, :notify_message_email
    remove_column :users, :notify_message_sms
    
  end
end
