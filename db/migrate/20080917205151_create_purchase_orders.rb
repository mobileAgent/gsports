class CreatePurchaseOrders < ActiveRecord::Migration
  def self.up
    create_table :purchase_orders do |t|
      t.string   "rep_name"
      t.string   "po_number"
      t.integer  "user_id",    :limit => 11
      t.timestamps
    end
  end

  def self.down
    drop_table :purchase_orders
  end
end
