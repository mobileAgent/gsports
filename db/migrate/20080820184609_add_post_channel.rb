class AddPostChannel < ActiveRecord::Migration
  def self.up
    add_column :posts, :team_id, :integer
    add_column :posts, :league_id, :integer
  end

  def self.down
    remove_column :posts, :team_id
    remove_column :posts, :league_id
  end
end

