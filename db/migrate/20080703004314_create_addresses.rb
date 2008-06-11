class CreateAddresses < ActiveRecord::Migration
  def self.up
    create_table :addresses do |t|
       t.column :firstname, :string
       t.column :minitial, :string
       t.column :lastname, :string

       t.column :address1, :string
       t.column :address2, :string 
       t.column :city, :string

       t.column :state, :string 
       t.column :country, :string

       t.column :phone, :string
       t.column :email, :string

      t.timestamps
    end
  end

  def self.down
    drop_table :addresses
  end
end
