#
# Membership.address will soon be required
# If it is empty then get it from the first user
# 

class SetMembershipAddress < ActiveRecord::Migration
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

  def self.down
  end
end
