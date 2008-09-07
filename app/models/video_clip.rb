class VideoClip < ActiveRecord::Base

  belongs_to :video_asset
  belongs_to :user
  
  acts_as_commentable
  acts_as_taggable
  has_many :favorites, :as => :favoritable, :dependent => :destroy
  acts_as_activity :user
  before_destroy :save_deleted_video
  
  # Every clip needs a title
  validates_presence_of :title
  
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

  # For the sake of symmetry
  named_scope :for_user,
    lambda { |user| { :conditions => ["user_id = ?",user.id] } }

  # Clips created by users associated with a team
  named_scope :for_team,
    lambda { |team| { :conditions => ["public_video = ? and users.team_id = ?",true,team.id], :include => [:user] } }

  # Clips created by users associated with the specified league
  named_scope :for_league,
    lambda { |league| { :conditions => ["public_video = ? and users.league_id = ?",true,league.id], :include => [:user] } }
  
  def thumbnail_dockey
    dockey
  end
  
  def save_deleted_video
    return if self.dockey.nil?
    vd = DeletedVideo.new
    vd.dockey = self.dockey
    vd.video_id = self.id
    vd.title = self.title
    vd.video_type = VideoClip.to_s
    vd.deleted_by = self.user_id
    vd.deleted_at = Time.now
    vd.save!
  end

  def owner
    self.user
  end
  
end
