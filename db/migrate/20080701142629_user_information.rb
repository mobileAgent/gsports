class UserInformation < ActiveRecord::Migration
  def self.up
    add_column :users, :firstname, :string
    add_column :users, :minitial, :string
    add_column :users, :lastname, :string
    
    add_column :users, :address1, :string
    add_column :users, :address2, :string 
    add_column :users, :city, :string
    
    add_column :users, :state, :string 
    add_column :users, :country, :string
    
    add_column :users, :phone, :string
    
    Role.enumeration_model_updates_permitted = true

    Role.create(:name => 'team')
    Role.create(:name => 'league')
    Role.create(:name => 'scout')
    
  end

  def self.down
    remove_column :users, :firstname
    remove_column :users, :minitial
    remove_column :users, :lastname
    
    remove_column :users, :address1
    remove_column :users, :address2 
    remove_column :users, :city
    
    remove_column :users, :state 
    remove_column :users, :country
        
    remove_column :users, :phone
    
    Role.enumeration_model_updates_permitted = true
    
    Role[:team].destroy()
    Role[:league].destroy()
    Role[:scout].destroy()
    
  end
end
