
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


  
  
  
end
