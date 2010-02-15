class CreateParents < ActiveRecord::Migration
  def self.up
    create_table :parents do |t|

      t.integer :roster_entry_id
      t.integer :user_id

      t.string :firstname
      t.string :lastname
      t.string :email
      t.string :phone

      t.timestamps
    end
  end

  def self.down
    drop_table :parents
  end
  
end
