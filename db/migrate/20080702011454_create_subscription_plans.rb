class CreateSubscriptionPlans < ActiveRecord::Migration
   def self.up
     create_table :subscription_plans do |t|
        t.column :name, :string # displayable name
        t.column :cost, :decimal, :precision => 8, :scale => 2, :default => 0 #cost/month
        t.column :description, :text #displayable description of plan
        t.timestamps
     end
     add_column :roles, :subscription_plan_id, :integer
   end

   def self.down
     drop_table :subscription_plans
   end
end
