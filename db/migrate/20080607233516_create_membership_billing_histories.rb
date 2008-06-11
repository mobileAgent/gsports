class CreateMembershipBillingHistories < ActiveRecord::Migration
  def self.up
    create_table :membership_billing_histories do |t|
      t.column :authorization_reference_number, :string # For credit card payments
      t.column :payment_method, :string
      t.column :membership_id, :integer
      t.timestamps
    end
  end

  def self.down
    drop_table :membership_billing_histories
  end
end
