
require 'vendor/plugins/community_engine/app/models/user'

class User < ActiveRecord::Base

  validates_presence_of :firstname
  #validates_presence_of :minitial
  validates_presence_of :lastname
    
  validates_presence_of :address1
  #validates_presence_of :address2
  validates_presence_of :city
    
  #validates_presence_of :state 
  #validates_presence_of :country
    
  validates_presence_of :phone
  has_many :subscriptions
  has_many :memberships, :through => :subscriptions
  
  def team_admin?
    role && role.eql?(Role[:team])
  end
  
  def league_admin?
    role && role.eql?(Role[:league])
  end
  
  def scout_admin?
    role && role.eql?(Role[:scout])
  end  
  
  def full_name
    "#{firstname} #{lastname}"
  end
  
  
end
