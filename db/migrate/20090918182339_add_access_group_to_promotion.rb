class AddAccessGroupToPromotion < ActiveRecord::Migration
  def self.up
    add_column :promotions, :access_group_id, :integer
  end

  def self.down
    remove_column :promotions, :access_group_id
  end
end
