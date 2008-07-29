
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
  belongs_to :team
  has_many :video_assets
  has_many :video_clips
  has_many :video_reels
  
  def team_admin?
    role && role.eql?(Role[:team])
  end

  def team_staff?
    role && (role.eql?(Role[:team_staff]) || team_admin? )
  end
  
  def league_admin?
    role && role.eql?(Role[:league])
  end

  def league_staff?
    role && (role.eql?(Role[:league_staff]) || league_admin?)
  end
  
  def scout_admin?
    role && role.eql?(Role[:scout])
  end
  
  def scout_staff?
    role && (role.eql?(Role[:scout_staff]) || scount_admin?)
  end
  
  def full_name
    "#{firstname} #{lastname}"
  end
  
end
