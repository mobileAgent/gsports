
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

  [:team_avatar, :league_avatar, :league, :league_id, :ad_zone].each do |method|
    delegate method, :to => :team
  end

  named_scope :admin,
    :conditions => ["email = ?",ADMIN_EMAIL]

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

  def can_upload?
    admin? || team_staff? || league_staff?
  end

  def full_name
    "#{firstname} #{lastname}"
  end

  # Never let the login slug appear in urls or paths
  def to_param
    id.to_s
  end
  

  # Determine if this user can edit the specified video item
  def can_edit?(v)
    return true if self.admin?
    case v.class.to_s
    when 'VideoAsset'
      return true if (v.team_id && self.team_id == v.team_id && self.team_staff?)
      return true if (v.league_id && self.league_id == v.league_id && self.league_staff?)
    when 'VideoClip'
      return true if v.user_id == self.id
    when 'VideoReel'
      return true if v.user_id == self.id
    end
    return false
  end
  
  def make_member(billing_method, address,payment_authorization)
    mem = Membership.new(:billing_method=>billing_method)
    mem.cost = role.plan.cost
    mem.name = firstname + " " + minitial + " " + lastname

    history = MembershipBillingHistory.new
    history.authorization_reference_number = "sample"
    history.payment_method = billing_method
    mem.membership_billing_histories << history

    memberships << mem
    save
  end

  def set_payment(ccinfo)
    cc = CreditCard.new(:first_name => ccinfo.first_name,
                        :last_name => ccinfo.last_name,
                        :number => ccinfo.number,
                        :month => ccinfo.month,
                        :year => ccinfo.year,
                        :verification_value => ccinfo.verification_value)
   memberships[0].credit_card = cc
   save
  end

  def enabled?
    enabled
  end
  
end
