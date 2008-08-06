class AddUserEnabledFlag < ActiveRecord::Migration
  def self.up
    add_column :users, :enabled, :boolean
    execute 'update users set enabled = 1'
  end

  def self.down
    remove_column :users, :enabled
  end
end
