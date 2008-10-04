class AddPurchaseOrderDueDate < ActiveRecord::Migration
  def self.up
    add_column :purchase_orders, :due_date, :datetime
    execute "update purchase_orders set due_date = created_at + interval 2 week"
  end

  def self.down
    remove_column :purchase_orders, :due_date
  end
end
