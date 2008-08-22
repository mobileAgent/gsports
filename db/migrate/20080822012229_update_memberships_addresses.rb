class UpdateMembershipsAddresses < ActiveRecord::Migration
  # Fix any Membership addresses by pulling data from the first user
  # Necessary because we added the :address validation on Membership
  def self.up
    Membership.find(:all).each {|mem|
      if mem.address.nil?
        user = mem.users.first
        addr = Address.new
        addr.firstname = user.firstname
        addr.minitial = user.minitial
        addr.lastname = user.lastname
        addr.address1 = user.address1
        addr.address2 = user.address2
        addr.city = user.city
        addr.state = user.state
        addr.country = user.country
        addr.phone = user.phone
        addr.email = user.email
        addr.zip = user.zip
        mem.address = addr
        mem.save!
      end
    } 
  end
  # Nothing to do here
  def self.down
  end
end
