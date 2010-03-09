require 'fileutils'

class VideoAsset < ActiveRecord::Base
  
  include SharedItem
  include VideoUpload
 
  belongs_to :league
  belongs_to :team
  belongs_to :user
  belongs_to :home_team, :class_name => 'Team', :foreign_key => 'home_team_id'
  belongs_to :visiting_team, :class_name => 'Team', :foreign_key => 'visiting_team_id'
  has_many :video_clips, :dependent => :destroy
  belongs_to :shared_access, :dependent => :destroy

  #has_many :channel_videos, :as => :attachable, :dependent => :destroy
  has_many :access_item, :as => :item #, :dependent => :destroy

  
  # Every video needs a title
  validates_presence_of :title
  validates_presence_of :uploaded_file_path
  
  
  def validate_gamex()
    if gamex_league_id?
      
      #video_asset = VideoAsset.new(params[:video_asset])
      
      #params[:video_asset][:title] 
      home_team_name = @video_asset.home_team ? @video_asset.home_team.name : ''
      visiting_team_name = @video_asset.visiting_team ? @video_asset.visiting_team.name : ''
      @video_asset.title = "#{home_team_name} vs. #{visiting_team_name}, #{@video_asset.game_date}"
      
      if params[:access_item][:access_group_id].empty?
        @access_item = AccessItem.new(params[:access_item])
        @access_item.errors.add :access_group, "An Access Group is required."
        @video_asset.errors.add :id, "An Access Group is required."
      end
      
    end
  end
  
  
  acts_as_commentable
  acts_as_taggable
  acts_as_rateable
  
  has_many :favorites, :as => :favoritable, :dependent => :destroy
  acts_as_activity :user, :if => Proc.new{|r| r.video_status == 'ready' && r.public_video }
  
  attr_protected :team_name, :league_name


  before_destroy :save_deleted_video
  before_destroy { |item| AccessItem.destroy_all "item_id = #{item.id} and item_type = '#{item.type.to_s}'" }
  before_destroy { |item| ChannelVideo.destroy_all "video_id = #{item.id} and video_type = '#{item.type.to_s}'" }
  before_destroy { |item| Favorite.destroy_all "favoritable_id = #{item.id} and favoritable_type = '#{item.type.to_s}'" }
  before_destroy { |item| VideoHistory.destroy_all "video_asset_id = #{item.id}" }
  

  after_save do |video|
    activity = Activity.find_by_item_type_and_item_id('VideoAsset', video.id)
    if video.video_status == 'ready' && video.public_video && !activity
      video.create_activity_from_self 
    elsif ((video.video_status != 'ready' || !video.public_video) && activity)
      activity.destroy
    end
  end

  # Be careful, game_date can be nil
  [:year, :month, :day].each { |m| delegate m, :to => :game_date }

  # Video upload repository
  VIDEO_REPOSITORY = VIDEO_BASE+"/uploaded"
  
  # set indexes for sphinx
  define_index do
    indexes title, :sortable => true
    indexes description
    indexes gsan
    indexes updated_at, :sortable => true
    indexes tags.name, :as => :tag_names
    indexes comments.comment, :as => :comment_comments
    set_property :delta => true
    has created_at, updated_at, public_video
  end

  # Game metadata
  def self.GAME_LEVELS
    ["Varsity","JV","Recreational"]
  end

  def self.GAME_GENDERS
    ["Boys","Girls","Coed", "Mens", "Womens"]
  end

  def self.GAME_TYPES
    ["Regular Season", "Playoff", "Championship", "Scrimmage"]
  end
  
  named_scope :for_user,
    lambda { |user| { :conditions => ["(team_id IN (?) || league_id IN (?)) and video_status = 'ready' and (public_video = ? || user_id = ?)",(user.league_staff? ? user.league.team_ids : [ user.team_id ]), [ user.league_id ], true, user.id ] } }
  
  named_scope :for_team,
    lambda { |team| { :conditions => ["team_id=? and video_status = 'ready' and public_video = true", team.id] } }

  named_scope :references_team,
    lambda { |team| 
		{ 
			:conditions => ["(team_id=? or home_team_id=? or visiting_team_id=?) and video_status = 'ready' and public_video = true", team.id, team.id, team.id]
		} 
	}

  named_scope :for_league,
    lambda { |league| { :conditions => ["league_id = ? and video_status = 'ready' and public_video = true", league.id] } }

  named_scope :for_league_exclusive,
    lambda { |league| { :conditions => ["league_id = ? and team_id IS NULL and video_status = 'ready' and public_video = true", league.id] } }


  named_scope :ready,
    :conditions => ["video_status = 'ready' and dockey IS NOT NULL"]
  

  def self.video_repository
    VIDEO_REPOSITORY
  end

  # Move the swfuploaded tmp file into the repo with the user specified name
  def self.move_upload_to_repository(tmpfile,filename)
    FileUtils.makedirs VIDEO_REPOSITORY if ! File.exists?(VIDEO_REPOSITORY)
    fname = self.sanitize_filename(filename)
    if File.exists? "#{VIDEO_REPOSITORY}/#{fname}"
      dup=2
      if fname.index('.')
        ext=fname.split('.').last
        base=fname[0..(0-(ext.size+2))]
      else
        base=fname
        ext='unk'
      end
      while (File.exists? "#{VIDEO_REPOSITORY}/#{base}(#{dup}).#{ext}")
        dup+=1
      end
      fname = "#{base}(#{dup}).#{ext}"
    end
    full_path = "#{VIDEO_REPOSITORY}/#{fname}"
    if FileUtils.mv(tmpfile.path,full_path)
      full_path
    else
      nil
    end
  end

  def self.sanitize_filename(filename)
    name = filename.strip
    # Filename only no path
    name.gsub! /^.*(\\|\/)/, ''
    # replace all non alphanumeric, underscore or periods with underscore
    name.gsub! /[^\w\.\-]/, '_'
    
    # Remove multiple underscores
    name.gsub!(/\_+/, '_')

    name
  end

  # To support the video quickfind sport selection dropdown
  def self.sports(team_id=nil)
    cond = 'sport IS NOT NULL'
    #cond += " and team_id = #{team_id.to_i}" if team_id
    cond += " and (team_id = #{team_id.to_i} or home_team_id = #{team_id.to_i} or visiting_team_id = #{team_id.to_i})" if team_id
    
    VideoAsset.find(:all, 
                    :select => 'DISTINCT sport', 
                    :conditions => cond,
                    :order => 'sport ASC')
  end

  # To support the video quickfind season selection dropdown
  def self.seasons(team_id=nil)
    cond = 'game_date IS NOT NULL'
    cond += " and (team_id = #{team_id.to_i} or home_team_id = #{team_id.to_i} or visiting_team_id = #{team_id.to_i})" if team_id
    
    
    
    years = VideoAsset.find(:all, 
                            :select => "DISTINCT year(game_date) as season", 
                            :conditions => cond,
                            :order => "season ASC").map(&:season)
    years.inject([]) { |v,y| v << VideoAsset.new(:game_date => "#{y}-01-01") }
  end
  
  # this is a temporary fix while memcached is horking dates (actually it's probably activerecord)
  def self.seasons_cache
    cache = @@cache_seasons rescue nil
    if cache.nil?
      cache = @@cache_seasons = self.seasons
    end
    cache
  end
  
  def self.seasons_cache_delete
    @@cache_seasons = nil
  end

  # To be called externally to update status of queued videos
  def self.update_queued_assets
    vidavee = Vidavee.first
    session_token = vidavee.login
    check_count = 0
    save_count = 0
    video_assets = VideoAsset.find(:all, :conditions => "video_status = 'queued'")
    video_assets.each do |video_asset|
      check_count += 1
      vidavee.update_asset_record(session_token,video_asset)
      if (video_asset.video_status != 'queued')
        video_asset.save!
        save_count += 1
      end
    end
    return {:checked => check_count, :saved => save_count}
  end

  def team_name= team_name
    if (team_name && team_name.size > 0)
      self.team= find_or_create_team_by_name team_name
    end
  end

  def team_name
    team ? team.name : nil
  end

  def league_name= league_name
    if (league_name && league_name.size > 0)
      self.league= find_or_create_league_by_name league_name
    end
  end

  def league_name
    league ? league.name : nil
  end

  def home_team_name= team_name
    if (team_name && team_name.size > 0)
      self.home_team = find_or_create_team_by_name team_name
    end
  end

  def home_team_name
    home_team ? home_team.name : nil
  end
  
  def home_team_title_name
    home_team ? home_team.title_name : nil
  end
  
  def visiting_team_name= team_name
    if (team_name && team_name.size > 0)
      self.visiting_team = find_or_create_team_by_name team_name
    end
  end

  def visiting_team_name
    visiting_team ? visiting_team.name : nil
  end
  
  def visiting_team_title_name
    visiting_team ? visiting_team.title_name : nil
  end

  def thumbnail_dockey
    dockey
  end
  
  def owner
    self.user
  end

  def game_level_choices
    a = VideoAsset.GAME_LEVELS
    a << game_level unless (a.member?(game_level) || game_level.nil?)
    a
  end

  def game_type_choices
    a = VideoAsset.GAME_TYPES
    a << game_type unless (a.member?(game_type) || game_type.nil?)
    a
  end

  def league_video?
    league_id && team_id.nil?
  end

  def self.quickfind(params)
    cond = Caboose::EZ::Condition.new
    if ! params[:season].blank?
      cond.append ['year(game_date) = ? or game_date_str like ?',params[:season],"#{params[:season]}%"]
    end
    cond.append ['? in (video_assets.team_id,video_assets.home_team_id,video_assets.visiting_team_id)', params[:team]]
    cond.append ['sport = ?', params[:sport]]
    cond.append ['? in (teams.state_id,home_teams_video_assets.state_id,visiting_teams_video_assets.state_id)', params[:state]]
    cond.append ['? in (teams.county_name,home_teams_video_assets.county_name,visiting_teams_video_assets.county_name)', params[:county_name]]
    cond.append ['public_video = ?', true]
    # nested includes make query into left outer join
    @video_assets = VideoAsset.paginate(:conditions => cond.to_sql, :page => params[:page], :order => 'video_assets.updated_at DESC', :include => [:tags, :team, { :visiting_team => {} ,:home_team => {} }])
  end
  
  def can_download? user
    0 < GamexUser.count(:conditions=>{ :user_id=>user.id, :league_id=>self.gamex_league_id })
  end
  
  def download_url
    vidavee = Vidavee.first
    session_token = vidavee.login
    @vidavee_movie_path = vidavee.file_asset_path(self.dockey,session_token)
  end
  
  
  
  
  
  

  private
  
  def find_or_create_team_by_name team_name
    t = Team.find_or_create_by_name team_name
    if t.new_record?
      t.league_id = (self.league_id? ? self.league_id : User.admin.first.league_id)
      t.save!
    end
    t
  end
  
  def find_or_create_league_by_name league_name
    t = League.find_or_create_by_name league_name
    if t.new_record?
      t.save!
    end
    t
  end


  def save_deleted_video
    return if self.dockey.nil?
    vd = DeletedVideo.new
    vd.dockey = self.dockey
    vd.video_id = self.id
    vd.title = self.title
    vd.video_type = VideoAsset.to_s
    vd.deleted_by = self.user_id
    vd.deleted_at = Time.now
    vd.save!
  end

  
end







