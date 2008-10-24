class AddExternalEmailToMessages < ActiveRecord::Migration
  def self.up
    add_column :messages, :to_email, :string, :limit => 256
    add_column :sent_messages, :to_emails, :text
  end

  def self.down
    remove_column :messages, :to_email
    remove_column :sent_messages, :to_emails
  end
end
