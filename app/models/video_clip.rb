class VideoClip < ActiveRecord::Base
  include SharedItem

  belongs_to :video_asset
  belongs_to :user
  belongs_to :shared_access, :dependent => :destroy
  
  acts_as_commentable
  acts_as_taggable
  acts_as_rateable
  
  has_many :favorites, :as => :favoritable, :dependent => :destroy
  acts_as_activity :user, :if => Proc.new{|r| r.public_video }

  before_destroy :save_deleted_video
  before_destroy { |item| AccessItem.destroy_all "item_id = #{item.id} and item_type = '#{item.type.to_s}'" }
  before_destroy { |item| ChannelVideo.destroy_all "video_id = #{item.id} and video_type = '#{item.type.to_s}'" }
  before_destroy { |item| Favorite.destroy_all "favoritable_id = #{item.id} and favoritable_type = '#{item.type.to_s}'" }
  
  # Every clip needs a title
  validates_presence_of :title
  
  after_save do |video|
    activity = Activity.find_by_item_type_and_item_id('VideoClip', video.id)
    if video.public_video && !activity
      video.create_activity_from_self 
    elsif !video.public_video && activity
      activity.destroy
    end
  end
  
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

  def video_length=(length_string)
    if length_string.class.to_s != 'String' || length_string.index(':')
      self[:video_length] = length_string.to_s
    else
      begin
        raw_seconds = length_string.to_i
        if raw_seconds == 0
          self[:video_length] = length_string
        else
          h = raw_seconds / 3600
          m = "%02d" % ((raw_seconds - (h*3600)) / 60)
          s = "%02d" % (raw_seconds % 60)
          if h > 0
            self[:video_length] = "#{h}:#{m}:#{s}"
          else
            self[:video_length] = "#{m}:#{s}"
          end
        end
      rescue
        self[:video_length] = length_string
      end
    end
    self[:video_length]
  end
end
