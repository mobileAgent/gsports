class AddPurchaseOrdersToMemberships < ActiveRecord::Migration
  def self.up
    add_column :memberships, :purchase_order_id, :integer, :size => 11
    
    add_column :purchase_orders, :accepted, :boolean, :default => false
    add_column :purchase_orders, :accepted_at, :datetime
    add_column :purchase_orders, :accepted_by, :integer, :size => 11
  end

  def self.down
    remove_column :memberships, :purchase_order_id

    remove_column :purchase_orders, :accepted
    remove_column :purchase_orders, :accepted_at
    remove_column :purchase_orders, :accepted_by
  end
end
