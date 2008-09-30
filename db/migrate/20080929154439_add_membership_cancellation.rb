class AddMembershipCancellation < ActiveRecord::Migration
  def self.up
    
    create_table :membership_cancellations do |t|
      t.integer   "membership_id", :limit => 11, :null => false
      t.text      "reason"
      t.timestamps
    end
    add_index :membership_cancellations, ["membership_id"], :name => "index_mem_cancellations_on mem_id"

    add_column :memberships, :status, :char, :default => 'a'
    execute "update memberships set status='a' where status is null"
    add_index :memberships, ["status"], :name => "index_memberships_on_status"
  end

  def self.down
    drop_table :membership_cancellations
    remove_column :memberships, :status
  end
end