class MessagingForAccessGroups < ActiveRecord::Migration
  def self.up
    add_column :messages, :to_access_group_id, :integer
    add_column :sent_messages, :to_access_group_ids, :string, :limit => 255
  end

  def self.down
    remove_column :messages, :to_access_group_id
    remove_column :sent_messages, :to_access_group_ids
  end
end
