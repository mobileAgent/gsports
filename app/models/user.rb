
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
  #validates_presence_of :team_id
  
  def validate
    
    # limit staff accounts
    if enabled 
      members = nil
      limit = 3
      if league_staff?
        members = Staff.league_staff(league_id)
        limit = league.staff_limit || limit
      elsif team_staff?
        members = Staff.team_staff(team_id)
        limit = team.staff_limit || limit
      end
      if members
        count = members.delete_if{|u|u.id==id}.collect(&:enabled).delete_if{|e|!e}.size
        errors.add_to_base("You can only have #{limit} enabled staff members. You have #{count}") if(count >= limit)
      end
    end
  end


  #has_many :subscriptions
  #has_many :memberships, :through => :subscriptions
  has_many :memberships
  has_many :credit_cards
  belongs_to :team
  belongs_to :league
  has_many :video_assets
  has_many :video_clips
  has_many :video_reels
  has_many :video_users
  has_many :applied_monikers
  has_many :monikers, :through => :applied_monikers
  has_many :messages, :foreign_key => 'to_id'
  has_many :sent_messages, :foreign_key => 'from_id'
  
  has_many :gamex_users
  
  has_many :permissions, :as => :blessed


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

  named_scope :enabled,
     :conditions => ['enabled = ?',true]

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

  named_scope :third_party_staff,
    lambda { |org| { :conditions=>{ 'permissions.scope_type'=>org.class.to_s, 'permissions.scope_id'=>org.id }, :include=>:permissions } }




  # Those who can do things for the league account
  named_scope :league_staff,
    lambda { |league_id| { :conditions => ["league_id = ? and role_id IN (?)",league_id,[Role[:league_staff].id, Role[:league].id, Role[:admin].id] ] } }


  def mail_target_ids()
    @friend_ids = Friendship.find(:all, :conditions => ['user_id = ? and friendship_status_id = ?',self.id,FriendshipStatus[:accepted].id]).collect(&:friend_id)
    if team_staff?
      @friend_ids += User.team_staff(self.team.id).collect(&:id)
      @friend_ids.uniq!
    end
    @friend_ids
  end

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
    has created_at, updated_at, profile_public, enabled
    set_property :delta => true
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







#
# Access Management
#
#

  # Permission based role management

  # general

  def can?(role, scope=nil)
    admin? || Permission.check(self, role, scope)
  end

  def scopes_for(role)
    if admin?
      Permission.has_role(role).collect(&:scope).uniq.sort_by(){ |s| "#{s.class} #{s.name}"}
    else
      Permission.range(self, role)
    end
    
  end

  # specific

  # this is for video_assets, all users can upload video_users
  def can_upload?
    admin? || can?(Permission::UPLOAD)
    #admin? || team_staff? || league_staff?
  end

  def can_publish?(item=nil)
    can?(Permission::MANAGE_CHANNELS, (item.respond_to?(:team) ? item.team : nil) )
    #team_staff? && team.can_publish?(item)
  end

  def can_restrict?(item)
    can?(Permission::MANAGE_GROUPS, (item.respond_to?(:team) ? item.team : nil) )
    # team_staff? && item.class == VideoAsset && item.team_id == team_id && (AccessGroup.for_team(team).size > 0)
    ## team_staff? && item.public_methods.include?('team') && item.team_id == team_id && (AccessGroup.for_team(team).size > 0)
  end



  def can_manage_staff?(scope=nil)
    admin? || can?(Permission::CREATE_STAFF, scope)
  end


  def can_grant_access?(user=nil)

    can?(Permission::MANAGE_GROUPS)

#    in_general = team_staff? && (AccessGroup.for_team(team).size > 0)
#    if user
#      user.class == User && in_general
#    else
#      in_general
#    end
  end



  # legacy team_staff access

  # Determine if this user can edit the specified video* item

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
    when 'VideoUser'
      return true if v.user_id == self.id
    when 'Team'
      return true if team_admin?(v) || can?(Permission::EDIT_TEAM_PAGE, v)
    when 'League'
      return true if league_admin?(v) || can?(Permission::EDIT_TEAM_PAGE, v)
    end

    return false
  end





  # user identity roles


  def self.league_staff_ids(league_id)
    User.league_staff(league_id).collect(&:id)
  end

  def self.team_staff_ids(team_id)
    User.team_staff(team_id).collect(&:id)
  end

  def team_admin?(chk_team=nil)
    pass = role && role.eql?(Role[:team])
    pass &&= (chk_team == self.team) if(chk_team)
    pass
  end

  def team_staff?(chk_team=nil)
    pass = role && (role.eql?(Role[:team_staff]) || team_admin? )
    pass &&= (chk_team == self.team) if(chk_team)
    pass
  end

  def league_admin?(chk_league=nil)
    pass = role && role.eql?(Role[:league])
    pass &&= (chk_league == self.league) if(chk_league)
    pass
  end

  def league_staff?(chk_league=nil)
    pass = role && (role.eql?(Role[:league_staff]) || league_admin?)
    pass &&= (chk_league == self.league) if(chk_league)
    pass
  end

  def scout_admin?
    role && role.eql?(Role[:scout])
  end

  def scout_staff?
    role && (role.eql?(Role[:scout_staff]) || scount_admin?)
  end


  # gamex and group based item access

  def has_access?(item)
    #asset_list = []
    
    case item
    when VideoAsset
      #asset_list = [ item ]
      pass = team_staff?(item.team) || has_access_to_asset?(item)
      return pass
    when VideoClip
      #asset_list = [ item ] #.video_asset ]
      asset = item.video_asset
      pass = team_staff?(asset.team) || has_access_to_clip?(item) || (!needs_access_to_clip?(item) && has_access_to_asset?(asset))
      return pass
    when VideoReel
      #TODO cache this value, or store it to db?
      Vidavee.first.get_clip_dockeys_for_reel(item.dockey).each() { |dockey|
        #logger.debug "ABX:Reel Part: #{dockey}"
        clip_list = []

        if clip = VideoClip.find(:first, :conditions=>{ :dockey=>dockey })
          #logger.debug "ABX:Clip: #{clip ? clip.id : 'nil'}"
          clip_list <<  clip #.video_asset
        end

        clip_list.each() { |clip|
          asset = clip.video_asset
          pass = team_staff?(asset.team) || has_access_to_clip?(item) || has_access_to_asset?(asset)
          #logger.debug "Asset id #{asset.id} access: #{pass}"
          return false if !pass
        }

      }
    else
      return AccessGroup.allow_access?(self, item)
    end

    return true
  end
  
  def has_access_to_asset?(item)

    return true if admin?

    # assume we're good
    logger.info("has_access?")
    access_pass = true
  
    # unless it's a gamex video
    gamex_asset_id = nil
    
    if item.class == VideoAsset and item.gamex_league_id   
      gamex_asset_id = item.gamex_league_id
    end
    
    if gamex_asset_id      
      if 0 < GamexUser.count(:conditions => { :user_id => id, :league_id => gamex_asset_id } )
        logger.info("has_access? is coach")
        # is coach
        
        gamex_user = GamexUser.for_user_and_league(id, gamex_asset_id).first
        gamex_league = gamex_user.gamex_league
        
        return gamex_league ? gamex_league.release?(item) : true
      else
        logger.info("has_access? isn't coach but this is a gamex video, passing to access group check")
#        logger.info("has_access? isn't coach but this is a gamex video, need access to pass")
#        # isn't but this is a gamex video, need access to pass
#        access_pass = false
      end
    end

    logger.info("has_access? #{access_pass}")
    # or is guarded by access groups
    access_items = AccessItem.for_item(item)
    if access_items.any?
      access_pass = false
      logger.info("has_access? #{access_pass}")
      access_items.each{ |access_item|
        access_pass = true if (access_item.access_group.enabled && access_item.access_group.allow?(self) )
        logger.info("has_access? #{access_pass} on access group #{access_item.access_group_id} item #{access_item.id}")
      }
    end
    logger.info("has_access? #{access_pass}")
    
    access_pass
  end

  def needs_access_to_clip?(item)
    AccessItem.for_item(item).size > 0
  end

  # this has to be explicit access to override other access
  def has_access_to_clip?(item)
    (AccessItem.for_item(item) || []).each{ |access_item|
      return true if (access_item.access_group.enabled && access_item.access_group.allow?(self) )
    }
    false
  end

  


#
#  User Actions
#
#
  
  def make_member_by_invoice (monthly_cost, purchase_order, promotion=nil)
    mem = Membership.new(:billing_method => Membership::INVOICE_BILLING_METHOD)
    mem.name = full_name
    mem.purchase_order = purchase_order

    mem.cost = (monthly_cost.nil? ? role.plan.cost : monthly_cost) * 12
    
    # Next membership expiration comes after the end of the current
    # membership, if one exists and is active
    existing_mem = current_membership
    if existing_mem && 
          existing_mem.active? &&
          existing_mem.expiration_date && 
          existing_mem.expiration_date > Time.now
      mem.expiration_date = existing_mem.expiration_date + 12.months
    else
      mem.expiration_date = Time.now + 12.months
    end
    logger.debug "Invoice Expiration is #{mem.expiration_date}"
    
    if promotion
      # consider membership.apply_promotion()
      mem.promotion = promotion
      if !promotion.period_days.nil? && promotion.period_days > 0
        mem.expiration_date += promotion.period_days.days       
        logger.debug "Promotional Invoice Expiration is #{mem.expiration_date}"
      end
    end

    add_membership(mem)
  end
  
  def make_member_by_credit_card(monthly_cost, address, cc, payment_authorization, promotion=nil)
    mem = Membership.new(:billing_method => Membership::CREDIT_CARD_BILLING_METHOD)
    mem.cost = monthly_cost.nil? ? role.plan.cost : monthly_cost
    mem.name = full_name
    mem.credit_card = cc
    
    if payment_authorization # else we may just be updating cc info
      history = MembershipBillingHistory.new
      pf = payment_authorization.params
      history.authorization_reference_number = "#{pf['pn_ref']}/#{pf['auth_code']}"
      history.payment_method = mem.billing_method
      history.credit_card = mem.credit_card
      mem.membership_billing_histories << history
    end
    
    if promotion
      # consider membership.apply_promotion()
      mem.promotion = promotion
      if !promotion.period_days.nil? && promotion.period_days > 0
        mem.expiration_date = Time.now + promotion.period_days.days       
        logger.debug "Expiration is #{mem.expiration_date}"
      end
    end

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
        
    add_membership(mem)
  end

  def set_credit_card(ccinfo)
    cc = CreditCard.from_active_merchant_cc(ccinfo)
    cc.save

    mem = current_membership
    if !mem.nil?
      mem.credit_card = cc    
      mem.save
    end    
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
    team_id ? team.title_name : ''
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
    u = find :first, :conditions => ['email = ? and activated_at IS NOT NULL and enabled = true', login]
    u && u.authenticated?(password) && u.update_last_login ? u : nil
  end

  def self.authenticate_inactive(login,password)
    u = find :first, :conditions => ['email = ?', login]
    u && u.authenticated?(password) && u.update_last_login ? u : nil
  end
  
  def activity(page = {}, since = 1.week.ago)
    page.reverse_merge :size => 50, :current => 1
    
    ids = self.friends_ids
    Activity.find(:all, 
      :conditions => ['user_id = ? AND created_at > ? AND action <> ?', id, since,"logged_in"], 
      :order => 'created_at DESC',
      :page => page)      
  end

  # Modify original to not show login events
  def network_activity(page = {}, since = 1.week.ago)
    page.reverse_merge :size => 10, :current => 1
    
    ids = self.friends_ids
    Activity.find(:all, 
      :conditions => ['user_id in (?) AND created_at > ? AND action <> ? ', ids, since,"logged_in"], 
      :order => 'created_at DESC',
      :page => page)      
  end
  
  # Change the super class method to return the 
  # different sizes we need
  def avatar_photo_url(size = nil)
    if avatar
      avatar.public_filename(size)
    else
      case size
        when :thumb
          AppConfig.photo['missing_thumb']
        when :profile
          AppConfig.photo['missing_profile']
        when :icon
          AppConfig.photo['missing_thumb']
        when :feature
          AppConfig.photo['missing_thumb']
        else
          AppConfig.photo['missing_medium']
      end
    end
  end

  def can_send_message_to?(other_user)
    admin? || friends_ids.member?(other_user.id)
  end
  
  def current_membership
    mships = memberships.find(:all, :order=>:created_at)
    
    return nil if (mships.nil? or mships.empty?)    
    
    # The last membership should be the most recent.
    # If it is not active, then double check the rest
    # of the memberships to be sure that they are not
    # out of order and return an active one if found
    if !mships.last.active?
      # look for the first active membership
      mships.reverse.each do |m|
        logger.debug "testing membership ID #{m.id}, status #{m.status}, user #{m.user_id}"
        if m.active? || (m.status && m.status == Membership::STATUS_ACTIVE)
          logger.debug "returning membership ID #{m.id}"
          return m
        end
      end
    end

    m = mships.last
    if m
      logger.debug "returning last membership ID #{m.id}, status #{m.status}, user #{m.user_id}"
    end
    return m
  end

  def billing_needed?
    return false if Role.non_billable_role_ids.member?(role_id) 
    
    mem = current_membership
    return false if mem.nil? || !mem.active?
    
    if mem.cost > 0 && mem.billing_method == Membership::CREDIT_CARD_BILLING_METHOD
      if mem.last_billed.nil? || mem.last_billed < (Time.now - (PAYMENT_DUE_CYCLE+5).days)
        logger.info "NEED PAYMENT: #{mem.cost} last billed #{mem.last_billed}"
        return true
      end
    end
    false
  end

  def credit_card_expired?
    mem = current_membership
    return false if mem.nil?
    
    if mem.credit_card != nil && mem.credit_card.expired?
      logger.info "CREDIT CARD EXPIRED: #{mem.credit_card.expiration_date}"
      return true
    end

    false
  end
  
  def pending_purchase_order?
    mem = current_membership
    return false if mem.nil?
    
    if mem.cost > 0 &&
          mem.billing_method == Membership::INVOICE_BILLING_METHOD &&
          (mem.purchase_order.nil? || !mem.purchase_order.accepted)
      logger.info "INVOICE NOT YET PAID: #{mem.cost}"
      return true
    end
    false
  end


  def credit_card
    # use credit card from current membership
    mem = current_membership    
    if !mem.nil? && !mem.credit_card.nil?
      return mem.credit_card
    elsif credit_cards != nil && credit_cards.size > 0
      return credit_cards.first
    end
    
    nil
  end
  
  protected 
  
  def add_membership(membership)
    if membership
      # check to see if this is a renewal
      existing_mem = current_membership
      if existing_mem && (existing_mem.active? || existing_mem.expired?)
        logger.debug "Flagging existing membership as renewal"
        existing_mem.status = Membership::STATUS_RENEWED
        existing_mem.save!
      end
      
      memberships << membership
      save
    end    
  end
  
end
