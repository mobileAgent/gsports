class RemoveSubscriptions < ActiveRecord::Migration
  def self.up
    add_column :memberships, :user_id, :integer, :size => 11, :null => false
    add_index :memberships, ["user_id"], :name => "index_memberships_on_user_id"
    
    execute "update memberships set user_id=(select user_id from subscriptions s where s.membership_id=memberships.id)"
    
    drop_table :subscriptions
  end

  def self.down    
    create_table :subscriptions do |t|
      t.integer   "membership_id", :limit => 11
      t.integer   "user_id", :limit => 11
      t.timestamps
    end
    
    execute "insert into subscriptions (membership_id, user_id, created_at, updated_at) select id, user_id, created_at, updated_at from memberships"
    
    remove_column :memberships, :user_id
  end
end
