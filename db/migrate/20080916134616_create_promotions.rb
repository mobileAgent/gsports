class CreatePromotions < ActiveRecord::Migration
  def self.up
    create_table :promotions do |t|
      t.string :promo_code, :null => false, :limit => 30
      t.integer :subscription_plan_id, :limit => 11
      t.string :name, :limit => 255
      t.column :cost, :decimal, :precision => 8, :scale => 2
      t.text :content
      t.text :html_content
      t.timestamps
    end

    add_index "promotions", ["promo_code"], :unique => true, :name => "index_promotions_on_promo_code" 
    
    add_column :memberships, :promotion_id, :integer, :size => 11
  end

  def self.down
    drop_table :promotions
    remove_column :memberships, :promotion_id
  end
end
