class VideoClipsController < BaseController
  include Viewable
  
  before_filter :login_required
  before_filter :vidavee_login
  skip_before_filter :verify_authenticity_token, :only => [:create]
  
  uses_tiny_mce(:options => AppConfig.narrow_mce_options.merge({:width => 530}),
                :only => [:show])
  
  # GET /video_clips
  # GET /video_clips.xml
  def index
    
    @user = params[:user_id] ? User.find(params[:user_id]) : current_user
    cond = Caboose::EZ::Condition.new
    cond.user_id == @user.id
    if params[:tag_name]    
      cond.append ['tags.name = ?', params[:tag_name]]
    end
    
    @video_clips = VideoClip.paginate(:conditions => cond.to_sql, :page => params[:page], :order => 'created_at DESC')
    @tags = VideoClip.tags_count :user_id => @user.id, :limit => 20

    # Remove private clips from results
    if (! current_user.admin? )
      @video_clips.reject!{|v| v.public_video == false && v.user_id != current_user.id}
    end
    
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @video_clips }
    end
  end

  # GET /video_clips/1
  # GET /video_clips/1.xml
  def show
    @video_clip = VideoClip.find(params[:id])
    update_view_count(@video_clip)

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @video_clip }
    end
  rescue ActiveRecord::RecordNotFound
    flash[:notice] = 'That clip could not be found.'
    redirect_to url_for({ :controller => "search", :action => "my_videos" })
  end

  # GET /video_clips/new
  # GET /video_clips/new.xml
  def new
    @video_clip = VideoClip.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @video_clip }
    end
  end

  # GET /video_clips/1/edit
  def edit
    @video_clip = VideoClip.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    flash[:notice] = 'That clip could not be found.'
    redirect_to url_for({ :controller => "search", :action => "my_videos" })
  end

  # POST /video_clips
  # POST /video_clips.xml
  def create
    if (params[:dockey])
      logger.debug("reel creation from flash")
      from_flash = true
      @video_clip = VideoClip.new
      @video_clip.user = current_user
      @video_clip.title = params[:title]
      @video_clip.description = params[:description]
      @video_clip.dockey = params[:dockey]
      @video_clip.video_asset_id = params[:video_asset_id]
      @video_clip.public_video = params[:public_video]
      @video_clip.tag_with(params[:tag_list]) if (params[:tag_list])
    else
      @video_clip = VideoClip.new(params[:video_clip])
      @video_clip.tag_with(params[:tag_list] || '') 
    end
    
    saved = @video_clip.save!

    if (from_flash)
      render :inline => saved ? "#{@video_clip.to_xml}" : "<error>#{@video_clip.errors.join(',')}</error>"
      return
    end
    
    respond_to do |format|
      if saved
        flash[:notice] = 'VideoClip was successfully created.'
        format.html { redirect_to(@video_clip) }
        format.xml  { render :xml => @video_clip, :status => :created, :location => @video_clip }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @video_clip.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /video_clips/1
  # PUT /video_clips/1.xml
  def update
    @video_clip = VideoClip.find(params[:id])
    @video_clip.tag_with(params[:tag_list] || '') 

    respond_to do |format|
      if @video_clip.update_attributes(params[:video_clip])
        flash[:notice] = 'VideoClip was successfully updated.'
        format.html { redirect_to(@video_clip) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @video_clip.errors, :status => :unprocessable_entity }
      end
    end
  rescue ActiveRecord::RecordNotFound
    flash[:notice] = 'That clip could not be found.'
    redirect_to url_for({ :controller => "search", :action => "my_videos" })
  end

  # DELETE /video_clips/1
  # DELETE /video_clips/1.xml
  def destroy
    @video_clip = VideoClip.find(params[:id])
    @video_clip.destroy

    respond_to do |format|
      format.html { redirect_to(video_clips_url) }
      format.xml  { head :ok }
      format.js
    end
  rescue ActiveRecord::RecordNotFound
    flash[:notice] = 'That clip could not be found.'
    redirect_to url_for({ :controller => "search", :action => "my_videos" })
  end
  
  def thumbnail
    @video_clip = VideoClip.find(params[:id])
    send_data @vidavee.file_thumbnail_medium(session[:vidavee],@video_clip.dockey), :filename => "clip#{@video_clip.id}.jpg", :type => 'image/jpeg' 
  end
end
