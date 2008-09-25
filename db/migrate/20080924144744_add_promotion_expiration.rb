class AddPromotionExpiration < ActiveRecord::Migration
  def self.up
    add_column :promotions, :enabled, :boolean
    add_column :promotions, :reusable, :boolean
    add_column :promotions, :period_days, :integer, :size => 4

    add_column :memberships, :expiration_date, :datetime
    
    execute "update promotions set enabled=true where enabled is null"
    execute "update promotions set reusable=false where reusable is null"
    execute "update promotions set period_days=60 where promo_code = 'GS60FREE'"
    execute "update memberships set expiration_date=date_add(created_at, interval (select p.period_days from promotions p where p.id=memberships.promotion_id) day) 
             where promotion_id is not null and expiration_date is null
               and exists (select 1 from promotions p where p.id=memberships.promotion_id and p.period_days > 0)"
  end

  def self.down
    remove_column :promotions, :enabled
    remove_column :promotions, :reusable
    remove_column :promotions, :period_days
    
    remove_column :memberships, :expiration_date
  end
end
