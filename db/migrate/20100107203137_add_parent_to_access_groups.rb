class AddParentToAccessGroups < ActiveRecord::Migration
  def self.up
    add_column :access_groups, :parent_id, :integer
  end

  def self.down
    remove_column :access_groups, :parent_id
  end
end
