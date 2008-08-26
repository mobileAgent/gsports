class TagsController < BaseController
  before_filter :login_required
  skip_before_filter :verify_authenticity_token, :only => [:auto_complete_for_tag_name]

  def auto_complete_for_tag_name
    look_for = params[:id] || params[:tag_list]
    if (look_for.nil?)
      myparams = params.clone
      myparams.delete('action')
      myparams.delete('controller')
      logger.debug "No id or tag_list, trying #{myparams.entries.first} which is a #{myparams.entries.first.class.to_s}"
      look_for = myparams.entries.first
      if look_for.class.to_s == "Array" && look_for.size == 2
        logger.debug "Dude it is an array of #{look_for[1].class.to_s}"
        look_for = look_for[1].values.first
      end
    end
    logger.debug "Tag completion searching for '#{look_for}'"
    @tags = Tag.find_list(look_for)
    render :inline => "<%= auto_complete_result(@tags, 'name') %>"
  end
  
  def index  
    @tags = popular_tags(100, ' count DESC')
    @user_tags = popular_tags(75, ' count DESC', 'User')
    @post_tags = popular_tags(75, ' count DESC', 'Post')
    @photo_tags = popular_tags(75, ' count DESC', 'Photo')
    @clipping_tags = popular_tags(75, ' count DESC', 'Clipping')
    @video_assets = popular_tags(75, ' count DESC', 'VideoAsset')
    @video_clips = popular_tags(75, ' count DESC', 'VideoClip')
    @video_reels = popular_tags(75, ' count DESC', 'VideoReel')
    @applied_monikers = popular_tags(75, ' count DESC', 'AppliedMoniker')
  end
  
  def show
    @tag = Tag.find_by_name(params[:id])
    if @tag.nil? 
      flash[:notice] = "The tag #{params[:id]} does not exist."
      redirect_to :action => :index and return
    end
    @related_tags = @tag.related_tags
    
    if params[:type]
      cond = Caboose::EZ::Condition.new
      cond.append ['tags.name = ?', @tag.name]
      @posts, @photos, @users, @clippings = [], [], [], []
      @video_assets, @video_clips, @video_reels = [], [], []
      @applied_monikers = []
      
      case params[:type]
        when 'Post'
          @pages, @posts = paginate :posts, :order => "published_at DESC", :conditions => cond.to_sql, :include => :tags, :per_page => 20
        when 'Photo'
          @pages, @photos = paginate :photos, :order => "created_at DESC", :conditions => cond.to_sql, :include => :tags, :per_page => 30
        when 'User'
          @pages, @users = paginate :users, :order => "created_at DESC", :conditions => cond.to_sql, :include => :tags, :per_page => 30
          @bogus_pages, @applied_monikers = paginate :applied_monikers, :order => "created_at DESC", :conditions => cond.to_sql, :include => :tags, :per_page => 30
        when 'Clipping'
          @pages, @clippings = paginate :clippings, :order => "created_at DESC", :conditions => cond.to_sql, :include => :tags, :per_page => 30      
        when 'VideoAsset'
          @pages, @video_assets = paginate :video_assets, :order => "created_at DESC", :conditions => cond.to_sql, :include => :tags, :per_page => 30      
        when 'VideoClip'
          @pages, @video_clips = paginate :video_clips, :order => "created_at DESC", :conditions => cond.to_sql, :include => :tags, :per_page => 30      
        when 'VideoReel'
          @pages, @video_reels = paginate :video_reels, :order => "created_at DESC", :conditions => cond.to_sql, :include => :tags, :per_page => 30
        when 'AppliedMoniker'
          @pages, @applied_monikers = paginate :applied_monikers, :order => "created_at DESC", :conditions => cond.to_sql, :include => :tags, :per_page => 30
        end
    else
      @posts = Post.find_tagged_with(@tag.name, :limit => 5, :order => 'published_at DESC', :sql => " AND published_as = 'live'")
      @photos = Photo.find_tagged_with(@tag.name, :limit => 10, :order => 'created_at DESC')
      @users = User.find_tagged_with(@tag.name, :limit => 10, :order => 'created_at DESC').uniq
      @clippings = Clipping.find_tagged_with(@tag.name, :limit => 10, :order => 'created_at DESC')
      @video_assets = VideoAsset.find_tagged_with(@tag.name, :limit => 10, :order => 'created_at DESC')
      @video_clips = VideoClip.find_tagged_with(@tag.name, :limit => 10, :order => 'created_at DESC')
      @video_reels = VideoReel.find_tagged_with(@tag.name, :limit => 10, :order => 'created_at DESC')
      @applied_monikers = AppliedMoniker.find_tagged_with(@tag.name, :limit => 10, :order => 'created_at DESC')
    end
  end
  
end
