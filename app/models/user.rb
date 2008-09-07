
require 'vendor/plugins/community_engine/app/models/user'

class User < ActiveRecord::Base

  validates_presence_of :firstname
  #validates_presence_of :minitial
  validates_presence_of :lastname

  validates_presence_of :address1
  #validates_presence_of :address2
  validates_presence_of :city

  validates_presence_of :state
  #validates_presence_of :country

  validates_presence_of :phone
  validates_presence_of :team_id

  has_many :subscriptions
  has_many :memberships, :through => :subscriptions
  belongs_to :team
  belongs_to :league
  has_many :video_assets
  has_many :video_clips
  has_many :video_reels
  has_many :applied_monikers
  has_many :monikers, :through => :applied_monikers
  has_many :messages, :foreign_key => 'to_id'
  has_many :sent_messages, :foreign_key => 'from_id'
  
  belongs_to :country

  # Base model uses has_enumerated here, but at least fixtures
  # don't work with that. This takes care of the foxy fixtures
  # issue, but does this break anything else? If so, remove it
  # and the change the fixures/users.yml to use role_id instead of role
  belongs_to :role

  attr_protected :team_name, :league_name

  [:team_avatar, :ad_zone].each do |method|
    delegate method, :to => :team
  end

  named_scope :admin,
    :conditions => ["email = ?",ADMIN_EMAIL]

  # The billing entity for the team account
  named_scope :team_admin,
    lambda { |team_id| { :conditions => ["team_id = ? and role_id = ?",team_id,Role[:team].id] } }

  # The billing entity for the league account
  named_scope :league_admin,
   lambda { |league_id| { :conditions => ["league_id = ? and role_id = ?",league_id,Role[:league].id] } }

  # Those who can do things for the team account
  named_scope :team_staff,
    lambda { |team_id| { :conditions => ["team_id = ? and role_id IN (?)",team_id,[Role[:team_staff].id,Role[:team].id, Role[:admin].id] ] } }

  # Those who can do things for the league account
  named_scope :league_staff,
    lambda { |league_id| { :conditions => ["league_id = ? and role_id IN (?)",league_id,[Role[:league_staff].id, Role[:league].id, Role[:admin].id] ] } }

  # set indexes for sphinx
  define_index do
    indexes [firstname,lastname], :as => :full_name, :sortable => true
    indexes :description
    indexes updated_at, :sortable => true
    indexes [address1, address2, city, zip, state.name], :as => :address
    indexes team.name, :as => :team_name
    indexes league.name, :as => :league_name
    indexes tags.name, :as => :tags_content
    indexes comments.comment, :as => :comment_comments
    
    indexes friendships.friend_id, :as => :friend_id
    
    
    #indexes monikers.tags.name, :as => :moniker_content
    has created_at, updated_at, profile_public
  #  set_property :delta => true
  end

  def self.league_staff_ids(league_id)
    User.league_staff(league_id).collect(&:id)
  end

  def self.team_staff_ids(team_id)
    User.team_staff(team_id).collect(&:id)
  end

  def team_admin?(chk_team=nil)
    pass = role && role.eql?(Role[:team])
    pass &&= (chk_team == team) if(chk_team)
    pass
  end

  def team_staff?(chk_team=nil)
    pass = role && (role.eql?(Role[:team_staff]) || team_admin? )
    pass &&= (chk_team == team) if(chk_team)
    pass
  end

  def league_admin?(chk_league=nil)
    pass = role && role.eql?(Role[:league])
    pass &&= (chk_league == league) if(chk_league)
    pass
  end

  def league_staff?(chk_league=nil)
    pass = role && (role.eql?(Role[:league_staff]) || league_admin?)
    pass &&= (chk_league == league) if(chk_league)
    pass
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

  # Override CE
  def display_name
    full_name
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
    mem.name = full_name

    # if no address provided use the address data in me
    if address.nil?
      addr = Address.new
      addr.firstname = firstname
      addr.minitial = minitial
      addr.lastname = lastname
      addr.address1 = address1
      addr.address2 = address2
      addr.city = city
      addr.state = state
      addr.country = country
      addr.phone = phone
      addr.email = email
      addr.zip = zip
      mem.address = addr
    else
      mem.address = address
    end

    if payment_authorization # else we may just be updating cc info
      history = MembershipBillingHistory.new
      pf = payment_authorization.params
      history.authorization_reference_number = "#{pf['pn_ref']}/#{pf['auth_code']}"
      history.payment_method = billing_method
      mem.membership_billing_histories << history
    end
    memberships << mem
    save
  end

  def set_payment(ccinfo)
    cc = CreditCard.new(:first_name => ccinfo.first_name,
                        :last_name => ccinfo.last_name,
                        :number => ccinfo.number,
                        :month => ccinfo.month,
                        :year => ccinfo.year,
                        :verification_value => ccinfo.verification_value,
                        :displayable_number => ccinfo.number[(ccinfo.number.length - 4)..ccinfo.number.length])
   memberships[0].credit_card = cc
   save
  end

  def enabled?
    enabled
  end

  def tag_moniker(moniker_name,tag_list)
    # May need to create the user_generated moniker
    m = Moniker.find_or_create_by_name(moniker_name)
    self.monikers << m if (!self.monikers.member?(m))
    am = self.applied_monikers.find_or_create_by_moniker_id(m.id)
    am.tag_with(tag_list)
  end

  def moniker_hash
    mh = self.applied_monikers.inject({}) { |s,am| s.merge( { am.name => am.tags.collect(&:name) } ) }
    Moniker.system.each do |sysmoniker|
      if (! mh.has_key?(sysmoniker.name))
        mh[sysmoniker.name] = []
      end
    end
    mh
  end

  # Quick hack to get auto complete access to system monikers
  # until I can figure out more metaprogramming juju
  Moniker.system.collect(&:name).each do |mname|
    define_method "moniker_#{mname}_tag_list" do
      moniker_hash["#{mname}"].join(", ")
    end
    define_method "moniker_#{mname}_tag_list=" do |tag_list|
      tag_moniker("#{mname}",tag_list)
    end
  end

  def team_name
    team_id? ? team.title_name : ''
  end

  # Unless the role is league or league_staff, use team->league
  def league_name
    if (league_staff?)
      return League.find(league_id).name if league_id?
      return nil
    end
    return nil if team_id.nil?
    return team.league_name
  end

  # Unless the role is league or league_staff, use team->league
  def league_avatar
    return team.league_avatar unless league_staff?
    return League.find(league_id).avatar
  end

  # Unless the role is league or league_staff, use team->league
  def league
    return team.league unless league_staff?
    return League.find(league_id)
  end

  def byline
    tlname = league_staff? ? (League.find(league_id).name) : team_name
    "#{full_name}, #{tlname}"
  end
    
  # Authenticates a user by their login name and unencrypted password.  Returns the user or nil.
  # We only do this by email and we also handle disabled user accounts
  def self.authenticate(login, password)
    # hide records with a nil activated_at
    u = find :first, :conditions => ['email = ? and activated_at IS NOT NULL and enabled = true', login] if u.nil?
    u && u.authenticated?(password) && u.update_last_login ? u : nil
  end
  
  def activity(page = {}, since = 1.week.ago)
    page.reverse_merge :size => 50, :current => 1
    
    ids = self.friends_ids
    Activity.find(:all, 
      :conditions => ['user_id = ? AND created_at > ?', id, since], 
      :order => 'created_at DESC',
      :page => page)      
  end

end
