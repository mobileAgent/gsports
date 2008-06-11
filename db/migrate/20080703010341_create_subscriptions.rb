class CreateSubscriptions < ActiveRecord::Migration
  def self.up
    create_table :subscriptions do |t|
       t.column :membership_id, :integer
       t.column :user_id, :integer
       t.timestamps
    end
  end

  def self.down
    drop_table :subscriptions
  end
end
