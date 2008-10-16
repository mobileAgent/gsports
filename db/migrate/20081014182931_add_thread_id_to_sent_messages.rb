class AddThreadIdToSentMessages < ActiveRecord::Migration
  def self.up
    add_column :sent_messages, :thread_id, :integer
  end

  def self.down
    remove_column :sent_messages, :thread_id
  end
end
