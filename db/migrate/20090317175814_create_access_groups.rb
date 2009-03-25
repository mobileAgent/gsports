class CreateAccessGroups < ActiveRecord::Migration
  
  def self.up
    
    create_table :access_groups do |t|
      t.string   :name,         :limit => 30
      t.string   :description,  :limit => 30
      t.integer  :team_id,      :limit => 11
      t.boolean  :enabled
    end

    create_table :access_users do |t|
      t.integer  :access_group_id, :limit => 11
      t.integer  :user_id, :limit => 11
    end
    
    create_table :access_items do |t|
      t.integer  :access_group_id, :limit => 11
      t.string   :item_type
      t.integer  :item_id, :limit => 11
    end
    
    add_index(:access_items, [ :item_type, :item_id ])
    
  end

  def self.down
    drop_table :access_groups
    drop_table :access_users
    drop_table :access_items
  end
  
end
