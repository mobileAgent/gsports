require 'fileutils'
class VideoAsset < ActiveRecord::Base
  
  belongs_to :league
  belongs_to :team
  belongs_to :user
  belongs_to :home_team, :class_name => 'Team', :foreign_key => 'home_team_id'
  belongs_to :visiting_team, :class_name => 'Team', :foreign_key => 'visiting_team_id'
  has_many :video_clips, :dependent => :destroy
  
  acts_as_commentable
  acts_as_taggable
  has_many :favorites, :as => :favoritable, :dependent => :destroy
  acts_as_activity :user, :if => Proc.new{|r| r.video_status == 'ready' }
  
  attr_protected :team_name, :league_name
  before_destroy :save_deleted_video
  
  # Every video needs a title
  validates_presence_of :title

  # Be careful, game_date can be nil
  [:year, :month, :day].each { |m| delegate m, :to => :game_date }

  # Video upload repository
  VIDEO_REPOSITORY = VIDEO_BASE+"/uploaded"
  
  # set indexes for sphinx
  define_index do
    indexes title, :sortable => true
    indexes description
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
    ["regular season", "playoff", "championship", "scrimmage"]
  end
  
  named_scope :for_user,
    lambda { |user| { :conditions => ["(team_id IN (?) || league_id IN (?)) and video_status = 'ready' and (public_video = ? || user_id = ?)",(user.league_staff? ? user.league.team_ids : [ user.team_id ]), [ user.league_id ], true, user.id ] } }
  
  named_scope :for_team,
    lambda { |team| { :conditions => ["team_id = ? and video_status = 'ready' and public_video = true", team.id] } }

  named_scope :for_league,
    lambda { |league| { :conditions => ["league_id = ? and video_status = 'ready' and public_video = true", league.id] } }


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
  def self.sports
    VideoAsset.find(:all, 
                    :select => 'DISTINCT sport', 
                    :conditions => 'sport IS NOT NULL',
                    :order => 'sport ASC')
  end

  # To support the video quickfind season selection dropdown
  def self.seasons
    years = VideoAsset.find(:all, 
                            :select => "DISTINCT year(game_date) as season", 
                            :conditions => "game_date IS NOT NULL",
                            :order => "season ASC").map(&:season)
    years.inject([]) { |v,y| v << VideoAsset.new(:game_date => "#{y}-01-01") }
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
  
  def visiting_team_name= team_name
    if (team_name && team_name.size > 0)
      self.visiting_team = find_or_create_team_by_name team_name
    end
  end

  def visiting_team_name
    visiting_team ? visiting_team.name : nil
  end

  def thumbnail_dockey
    dockey
  end
  
  def owner
    self.user
  end

  def game_date_string
    return '' if game_date.nil?
    if ignore_game_day
      game_date.strftime("%Y-%m")
    else
      game_date.to_s(:game_date)
    end
  end

  def human_game_date_string
    return '' if game_date.nil?
    if ignore_game_day
      game_date.strftime("%B, %Y")
    else
      game_date.to_s(:readable)
    end
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
