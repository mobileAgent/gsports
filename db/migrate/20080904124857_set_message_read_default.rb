class SetMessageReadDefault < ActiveRecord::Migration
  def self.up
    change_column :messages, :read, :boolean, :default => false
    execute 'update messages set messages.read = false where messages.read is null'
  end

  def self.down
    # there is no down for this migration
  end
end
