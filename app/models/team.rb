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
  
  def self.find_list(tag_list)
    find(:all, :conditions => [ 'LOWER(name) LIKE ?', '%' + tag_list + '%' ])
  end
  
  # To support the video quickfind state selection dropdown
  def self.states
    State.find(:all,
               :select => 'DISTINCT states.id, states.name',
               :joins => 'JOIN teams on teams.state_id = states.id',
               :order => 'id ASC')
  end

  # To support the video quickfind county selection dropdown
  def self.counties(state_id=-1)
    if (state_id > -1)
      Team.find(:all, 
                :select => "DISTINCT county_name", 
                :conditions => "state_id = #{state_id} AND county_name IS NOT NULL and length(county_name) > 0",
                :order => 'county_name ASC')
    else
      Team.find(:all, 
                :select => "DISTINCT county_name", 
                :conditions => "county_name IS NOT NULL and length(county_name) > 0",
                :order => 'county_name ASC')
    end
  end
  
  def self.cities(county_id=-1)
    if (county_id > -1)
      Team.find(:all, 
                :select => "DISTINCT city", 
                :conditions => "county_id = #{county_id} AND city IS NOT NULL",
                :order => 'city ASC')
    else
      Team.find(:all, 
                :select => "DISTINCT city", 
                :conditions => "city IS NOT NULL and length(city) > 0",
                :order => 'city ASC')
    end
  end

  def self.schools(city_id=-1)
    if (city_id > -1)
      Team.find(:all, 
                :select => "DISTINCT name", 
                :conditions => "city_id = #{city_id} AND name IS NOT NULL",
                :order => 'name ASC')
    else
      Team.find(:all, 
                :select => "DISTINCT name", 
                :conditions => "name IS NOT NULL",
                :order => 'name ASC')
    end
  end

  def state_name
    state ? state.name : nil
  end

  def league_name
    league ? league.name : nil
  end
  
  def league_name= league_name
    self.league= League.find_or_create_by_name league_name
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
