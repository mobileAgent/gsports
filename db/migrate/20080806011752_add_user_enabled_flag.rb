class AddUserEnabledFlag < ActiveRecord::Migration
  def self.up
    add_column :users, :enabled, :boolean
    # Enable all existing users
    User.find(:all).each do |u|
      u.enabled = true
      u.save
    end
  end

  def self.down
  end
end
