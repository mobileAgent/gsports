class AddIndexToMemberships < ActiveRecord::Migration
  def self.up
    add_index :memberships, :created_at
  end

  def self.down
    remove_index :memberships, :created_at
  end
end
