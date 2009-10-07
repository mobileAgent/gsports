class VideoUser < ActiveRecord::Base

  include SharedItem
  include VideoUpload

  belongs_to :user
  has_many :video_clips, :dependent => :destroy
  belongs_to :shared_access, :dependent => :destroy

  # Every video needs a title
  validates_presence_of :title

  acts_as_commentable
  acts_as_taggable
  acts_as_rateable

  has_many :favorites, :as => :favoritable, :dependent => :destroy
  acts_as_activity :user, :if => Proc.new{|r| r.video_status == 'ready' && r.public_video }

  before_destroy :save_deleted_video
  before_destroy { |item| Favorite.destroy_all "favoritable_id = #{item.id} and favoritable_type = '#{item.type.to_s}'" }


  after_save do |video|
    activity = Activity.find_by_item_type_and_item_id('VideoUser', video.id)
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


  named_scope :for_user, lambda { |user| { :conditions => ["video_status = 'ready' and user_id = ?", user.id ] } }
    #lambda { |user| { :conditions => ["video_status = 'ready' and (public_video = ? || user_id = ?)", true, user.id ] } }

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


  # To be called externally to update status of queued videos
  def self.update_queued_user_videos
    vidavee = Vidavee.first
    session_token = vidavee.login
    check_count = 0
    save_count = 0
    video_users = VideoUser.find(:all, :conditions => "video_status = 'queued'")
    video_users.each do |video_asset|
      check_count += 1
      vidavee.update_asset_record(session_token,video_asset)
      if (video_asset.video_status != 'queued')
        video_asset.save!
        save_count += 1
      end
    end
    return {:checked => check_count, :saved => save_count}
  end


  def thumbnail_dockey
    dockey
  end

  def owner
    self.user
  end
  

  private


  def save_deleted_video
    return if self.dockey.nil?
    vd = DeletedVideo.new
    vd.dockey = self.dockey
    vd.video_id = self.id
    vd.title = self.title
    vd.video_type = VideoUser.to_s
    vd.deleted_by = self.user_id
    vd.deleted_at = Time.now
    vd.save!
  end

end
