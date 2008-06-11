class CreateMemberships < ActiveRecord::Migration
  def self.up
    create_table :memberships do |t|
      t.column :name, :string
      t.column :billing_method, :string
      # Cost kept here because it can differ from the current Subscription Plan cost
      t.column :cost,          :decimal, :precision => 8, :scale => 2, :default => 0
      t.column :address_id, :integer
      t.timestamps
    end
  end

  def self.down
    drop_table :memberships
  end
end
