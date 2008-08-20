class AddUsToUsersWithStates < ActiveRecord::Migration
  def self.up
    execute "update users set country_id = (select id from countries  where name = 'United States') where state_id is not null"
#    User.find(:all, :conditions => 'state_id is not null').each do |u|
#      u.update_attribute(:country_id, Country.get(:us).id.to_i)
#    end
  end

  def self.down
    execute "update users set country_id = null where state_id is not null"
#    User.find(:all, :conditions => 'state_id is not null').each do |u|
#      u.update_attribute(:country_id, nil)
#    end
  end
end
