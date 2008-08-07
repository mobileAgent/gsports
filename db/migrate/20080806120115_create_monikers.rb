class CreateMonikers < ActiveRecord::Migration
  def self.up
    create_table :monikers do |t|
      t.string :name, :null => false
      t.boolean :user_generated, :default => true

      t.timestamps
    end

    create_table :applied_monikers do |t|
      t.integer :moniker_id, :null => false
      t.integer :user_id, :null => false
      t.timestamps
    end
    
      execute "insert into monikers (name,user_generated,created_at,updated_at) values ('sports',0,'#{Time.now.to_s :db}','#{Time.now.to_s :db}')"
      execute "insert into monikers (name,user_generated,created_at,updated_at) values ('music',0,'#{Time.now.to_s :db}','#{Time.now.to_s :db}')"
      execute "insert into monikers (name,user_generated,created_at,updated_at) values ('movies',0,'#{Time.now.to_s :db}','#{Time.now.to_s :db}')"
      execute "insert into monikers (name,user_generated,created_at,updated_at) values ('teams',0,'#{Time.now.to_s :db}','#{Time.now.to_s :db}')"
  end

  def self.down
    drop_table :applied_monikers
    drop_table :monikers
  end
end
