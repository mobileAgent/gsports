class Team < ActiveRecord::Base


  has_many :video_assets
  belongs_to :league
  has_many :users
  belongs_to :avatar, :class_name => "Photo", :foreign_key => "avatar_id"
  belongs_to :state

  before_destroy :reassign_dependent_items

  # Every team needs a name and a league
  validates_presence_of :name
  validates_presence_of :league_id



  include Organization
  
  def get_org_id_from_object(o)
    case o
    when NilClass
      nil
    else
      o.team_id
    end
  end
  
  def get_self()
    self
  end



  # Every team should have a state
  # validates_presence_of :state_id

  # set indexes for sphinx
  define_index do
    indexes :name, :sortable => true
    indexes :nickname, :sortable => true
    indexes :description
    indexes :county_name
    indexes updated_at, :sortable => true
    indexes [address1, address2, city, zip, state.name, state.long_name], :as => :address
        
    has created_at, updated_at
    set_property :delta => true
  end
  

  delegate :league_avatar, :to => :league
  
  alias_method :team_avatar, :avatar

  named_scope :having_videos,
    :conditions => ["teams.id in (select distinct tid from (select team_id as tid from video_assets union select home_team_id as tid from video_assets union select visiting_team_id as tid from video_assets) ttt)"]

  def nickname_or_name()
    (nickname && !nickname.empty?) ? nickname : name
  end

  def self.find_list(tag_list)
    find(:all, :conditions => [ 'LOWER(name) LIKE ?', '%' + tag_list + '%' ])
  end
  
  # To support the video quickfind state selection dropdown
  def self.states
    State.find(:all,
               :select => 'DISTINCT states.id, states.name',
               :joins => 'JOIN teams on teams.state_id = states.id',
               :conditions => 'teams.id in (select distinct tid from (select team_id as tid from video_assets union select home_team_id as tid from video_assets union select visiting_team_id as tid from video_assets) ttt)',
               :order => 'id ASC')
  end

  # To support the video quickfind county selection dropdown
  def self.counties(state_id=-1)
    if (state_id > -1)
      Team.having_videos.find(:all, 
                :select => "DISTINCT county_name", 
                :conditions => ["state_id = ? AND county_name IS NOT NULL and length(county_name) > 0", state_id],
                :order => 'county_name ASC')
    else
      Team.having_videos.find(:all, 
                :select => "DISTINCT county_name", 
                :conditions => "county_name IS NOT NULL and length(county_name) > 0",
                :order => 'county_name ASC')
    end
  end
  
  def self.cities(state_id=nil)
    if state_id && state_id > 0
      cond = ["state_id = ? AND city IS NOT NULL",state_id]
    else
      cond = ["city IS NOT NULL and length(city) > 0"]
    end

    Team.having_videos.find(:all, 
              :select => "DISTINCT city", 
              :conditions => cond,
              :order => 'city ASC')
  end
    
  def self.oldcities(county_name=nil,state_id=nil)
    if county_name
      if state_id && state_id > 0
        cond = ["county_name = ? AND state_id = ? AND city IS NOT NULL",county_name,state_id]
      else
        cond = ["county_name = ? AND city IS NOT NULL",county_name]
      end
    else
      cond = ["city IS NOT NULL and length(city) > 0"]
    end

    Team.having_videos.find(:all, 
              :select => "DISTINCT city", 
              :conditions => cond,
              :order => 'city ASC')
  end

  def self.schools(city_id=-1)
    if (city_id > -1)
      cond = ["city_id = ? AND name IS NOT NULL", city_id]
    else
      cond = "name IS NOT NULL"
    end

    Team.having_videos.find(:all, 
              :select => "DISTINCT name", 
              :conditions => cond,
              :order => 'name ASC')
  end

  def state_name
    state ? state.name : nil
  end

  def league_name
    league ? league.name : nil
  end
  
  def league_name= league_name
    unless (league_name.nil? || league_name.blank?)
      self.league= League.find_or_create_by_name league_name
    end
  end

  def team_name
    self.name
  end

  def title_name
    if (self.nickname && !self.nickname.blank?)
      self.nickname
    else
      self.name
    end
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
    return nil if self.users.nil? || self.users.empty?
    logger.debug "Team has #{users.size} users"
    admins = self.users.find_all{|user| user.enabled? && user.role_id == Role[:team].id }
    return admins.empty? ? nil : admins[0]
  end

  def member?
    member = false
    Membership.for_team(self).each() { |membership|
      member = true if membership.active?
    }
    member
  end

  

  def staff()
    (User.third_party_staff(self) + User.team_staff(self.id)).uniq
  end

  def is_staff_account?(user)
    user.team_staff?(self)
  end

  protected
  
  
  def reassign_dependent_items
    logger.info "** Re-assigning teams before deleting #{self.id}"
    auser = User.admin.first :conditions => [ "team_id <> ?", self.id]
    if auser.nil? || auser.team_id == self.id
      raise ActiveRecord::ActiveRecordError.new("Cannot delete the admin team")
    end

    ateam_id = auser.team_id
    logger.debug "** New team id will be #{ateam_id}"
 
    v = VideoAsset.find_all_by_team_id(self.id)
    v.each { |x| x.update_attribute_with_validation_skipping(:team_id, ateam_id) }
    v = VideoAsset.find_all_by_home_team_id(self.id)
    v.each { |x| x.update_attribute_with_validation_skipping(:home_team_id, ateam_id) }
    v = VideoAsset.find_all_by_visiting_team_id(self.id)
    v.each { |x| x.update_attribute_with_validation_skipping(:visiting_team_id, ateam_id) }

    u = User.find_all_by_team_id(self.id)
    u.each { |x| x.update_attribute_with_validation_skipping(:team_id, ateam_id) }
 
    p = Post.find_all_by_team_id(self.id)
    p.each { |x| x.update_attribute_with_validation_skipping(:team_id, ateam_id) }
  end
  
end
