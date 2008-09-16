class CreateSorSearchLogs < ActiveRecord::Migration
  def self.up
    create_table :sor_search_logs do |t|
      t.integer :user_id
      t.string :lastname
      t.string :fisrtname
      t.string :state_name
      t.string :link
      t.boolean :is_sor ,:defaule =>false
      t.string :html_content
      t.timestamps
    end
  end

  def self.down
    drop_table :sor_search_logs
  end
end
