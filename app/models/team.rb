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

  delegate :league_avatar, :to => :league
  
  alias_method :team_avatar, :avatar

  named_scope :having_videos,
    :conditions => ["teams.id in (select distinct tid from (select team_id as tid from video_assets union select home_team_id as tid from video_assets union select visiting_team_id as tid from video_assets) ttt)"]
  
  
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
  
  def self.cities(county_name=nil,state_id=nil)
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
    if (self.nickname && self.nickname.length > 0)
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

  protected

  def reassign_dependent_items
    ateam_id = User.admin.first.team_id
    
    v = VideoAsset.find_all_by_team_id(self.id)
    v.each { |x| x.update_attributes(:team_id => ateam_id) }
    v = VideoAsset.find_all_by_home_team_id(self.id)
    v.each { |x| x.update_attributes(:home_team_id => ateam_id) }
    v = VideoAsset.find_all_by_visiting_team_id(self.id)
    v.each { |x| x.update_attributes(:visiting_team_id => ateam_id) }

    u = User.find_all_by_team_id(self.id)
    u.each { |x| x.update_attributes(:team_id => ateam_id) }
    
    p = Post.find_all_by_team_id(self.id)
    p.each { |x| x.update_attributes(:team_id => ateam_id) }
  end
  
end
