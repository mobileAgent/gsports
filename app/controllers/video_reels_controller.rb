class VideoReelsController < BaseController
  include Viewable
  
  before_filter :login_required
  before_filter :vidavee_login
  skip_before_filter :verify_authenticity_token, :only => [:create]
  
  # GET /video_reels
  # GET /video_reels.xml
  def index
    @user = params[:user_id] ? User.find(params[:user_id]) : current_user
    cond = Caboose::EZ::Condition.new
    cond.user_id == @user.id
    if params[:tag_name]    
      cond.append ['tags.name = ?', params[:tag_name]]
    end
    
    @video_reels = VideoReel.paginate(:conditions => cond.to_sql, :page => params[:page], :order => "created_at DESC", :include => :tags)
    @tags = VideoReel.tags_count :user_id => @user.id, :limit => 20
    
    # Remove private reels from results
    if (! current_user.admin? )
      @video_reels.reject!{|v| v.public_video == false && v.user_id != current_user.id}
    end

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @video_reels }
    end
  end

  # GET /video_reels/1
  # GET /video_reels/1.xml
  def show
    @video_reel = VideoReel.find(params[:id])
    update_view_count(@video_reel)

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @video_reel }
    end
  rescue ActiveRecord::RecordNotFound
    flash[:notice] = 'That reel could not be found.'
    redirect_to url_for({ :controller => "search", :action => "my_videos" })
  end

  # GET /video_reels/new
  # GET /video_reels/new.xml
  def new
    @video_reel = VideoReel.new
    @user_clip_dockeys = VideoClip.for_user(current_user).find(:all, :order => 'created_at DESC', :limit => 100).collect(&:dockey).join(',')
    logger.debug("Found user clip dockeys #{@user_clip_dockeys}")
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @video_reel }
    end
  end

  # GET /video_reels/1/edit
  def edit
    @video_reel = VideoReel.find(params[:id])
    @user_clip_dockeys = VideoClip.for_user(current_user).find(:all, :order => 'created_at DESC', :limit => 100).collect(&:dockey).join(',')
    logger.debug("Found user clip dockeys #{@user_clip_dockeys}")
  rescue ActiveRecord::RecordNotFound
    flash[:notice] = 'That reel could not be found.'
    redirect_to url_for({ :controller => "search", :action => "my_videos" })
  end

  # POST /video_reels
  # POST /video_reels.xml
  def create
    if (params[:dockey])
      logger.debug("reel creation from flash")
      from_flash = true
      @video_reel = VideoReel.new
      @video_reel.user = current_user
      @video_reel.title = params[:title]
      @video_reel.description = params[:description]
      @video_reel.dockey = params[:dockey]
      @video_reel.public_video = params[:public_video]
      @video_reel.tag_with(params[:tag_list])
    else
      @video_reel = VideoReel.new(params[:video_reel])
      @video_reel.tag_with(params[:tag_list] || '')
    end
    
    saved = @video_reel.save!

    if (from_flash)
      render :inline => saved ? "#{@video_reel.to_xml}" : "<error>#{@video_reel.errors.join(',')}</error>"
      return
    end
    
    respond_to do |format|
      if (saved)
        flash[:notice] = 'VideoReel was successfully created.'
        format.html { redirect_to(@video_reel) }
        format.xml  { render :xml => @video_reel, :status => :created, :location => @video_reel }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @video_reel.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /video_reels/1
  # PUT /video_reels/1.xml
  def update
    @video_reel = VideoReel.find(params[:id])

    respond_to do |format|
      @video_reel.tag_with(params[:tag_list] || '') 
      if @video_reel.update_attributes(params[:video_reel])
        flash[:notice] = 'VideoReel was successfully updated.'
        format.html { redirect_to(@video_reel) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @video_reel.errors, :status => :unprocessable_entity }
      end
    end
  rescue ActiveRecord::RecordNotFound
    flash[:notice] = 'That reel could not be found.'
    redirect_to url_for({ :controller => "search", :action => "my_videos" })
  end

  # DELETE /video_reels/1
  # DELETE /video_reels/1.xml
  def destroy
    @video_reel = VideoReel.find(params[:id])
    @video_reel.destroy

    respond_to do |format|
      format.html { redirect_to(video_reels_url) }
      format.xml  { head :ok }
    end
  rescue ActiveRecord::RecordNotFound
    flash[:notice] = 'That reel could not be found.'
    redirect_to url_for({ :controller => "search", :action => "my_videos" })
  end
end
