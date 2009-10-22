class League < ActiveRecord::Base

  has_many :video_assets
  has_many :teams
  has_many :users, :through => :teams, :source => :users
  belongs_to :state
  belongs_to :avatar, :class_name => "Photo", :foreign_key => "avatar_id"
  
  before_destroy :reassign_dependent_items
  
  # Every league needs a name
  validates_presence_of :name
  validates_presence_of :state_id

  
  include Organization
  
  def get_org_id_from_object(o)
    case o
    when NilClass
      nil
    else
      o.league_id
    end
  end
  
  def get_self()
    self
  end
  

  # set indexes for sphinx
  define_index do
    indexes :name, :sortable => true
    indexes :description
    indexes updated_at, :sortable => true
    indexes [address1, address2, city, zip, state.name, state.long_name], :as => :address
    
    has created_at, updated_at
    set_property :delta => true
  end



  alias_method :league_avatar, :avatar
  
  def self.find_list(tag_list)
    find(:all, :conditions => [ 'LOWER(name) LIKE ?', '%' + tag_list + '%' ])
  end

  def state_name
    state ? state.name : nil
  end

  def league_name
    self.name
  end

  def staff()
    (User.third_party_staff(self) + User.league_staff(self.id)).uniq
  end

  def is_staff_account?(user)
    user.league_staff?(self)
  end
  
  def avatar_photo_url(size = nil)
    if avatar
      avatar.public_filename(size)
    else
      case size
        when :thumb
          AppConfig.photo['missing_thumb']
        else
          AppConfig.photo['missing_medium']
      end
    end
  end

  def admin_user
    # need to use the named_scope to pull the users for this league
    # since users are not always pulled by the ActiveRecord
    admins = User.league_admin(self.id)
    logger.debug "League has #{admins.size} admin users"
    return admins.empty? ? nil : admins[0]
  end
  
  def member?
    member = false
    Membership.for_league(self).each() { |membership|
      member = true if membership.active?
    }
    member
  end

  protected

  def reassign_dependent_items
    logger.info "** Re-assigning leagues before deleting #{self.id}"
    auser = User.admin.first :conditions => [ "league_id <> ?", self.id]
    if auser.nil? || auser.league_id == self.id
      raise ActiveRecord::ActiveRecordError.new "Cannot delete the admin league"
    end

    alg_id = auser.league_id
    logger.debug "** New league id will be #{alg_id}"

    alg_id = User.admin.first.league_id
    v = VideoAsset.find_all_by_league_id(self.id)
    v.each { |x| x.update_attribute_with_validation_skipping(:league_id, alg_id) }

    u = User.find_all_by_league_id(self.id)
    u.each { |x| x.update_attribute_with_validation_skipping(:league_id, alg_id) }

    t = Team.find_all_by_league_id(self.id)
    t.each { |x| x.update_attribute_with_validation_skipping(:league_id, alg_id) }
                                   
    p = Post.find_all_by_league_id(self.id)
    p.each { |x| x.update_attribute_with_validation_skipping(:league_id, alg_id) }
    
  end
  
end
