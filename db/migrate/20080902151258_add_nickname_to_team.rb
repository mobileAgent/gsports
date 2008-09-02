class AddNicknameToTeam < ActiveRecord::Migration
  def self.up
    add_column :teams, :nickname, :string
  end

  def self.down
    remove_column :teams, :nickname
  end
end

