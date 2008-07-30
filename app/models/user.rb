
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
  validates_presence_of :team_id

  has_many :subscriptions
  has_many :memberships, :through => :subscriptions
  belongs_to :team
  has_many :video_assets
  has_many :video_clips
  has_many :video_reels

  # Base model uses has_enumerated here, but at least fixtures
  # don't work with that. This takes care of the foxy fixtures
  # issue, but does this break anything else? If so, remove it
  # and the change the fixures/users.yml to use role_id instead of role
  belongs_to :role

  [:team_avatar, :league_avatar, :league, :league_id].each do |method|
    delegate method, :to => :team
  end

  def team_or_league_avatar
    if team && team.avatar_id?
      team.avatar
    elsif league && league.avatar_id?
      league.avatar
    else
      User.find_by_email(ADMIN_EMAIL).team.avatar
    end
  end
      
  
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
