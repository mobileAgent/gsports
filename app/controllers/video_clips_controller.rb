class VideoClipsController < BaseController
  
  before_filter :login_required
  before_filter :vidavee_login
  
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

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @video_clips }
    end
  end

  # GET /video_clips/1
  # GET /video_clips/1.xml
  def show
    @video_clip = VideoClip.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @video_clip }
    end
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
  end

  # POST /video_clips
  # POST /video_clips.xml
  def create
    @video_clip = VideoClip.new(params[:video_clip])

    respond_to do |format|
      if @video_clip.save
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
  end

  # DELETE /video_clips/1
  # DELETE /video_clips/1.xml
  def destroy
    @video_clip = VideoClip.find(params[:id])
    @video_clip.destroy

    respond_to do |format|
      format.html { redirect_to(video_clips_url) }
      format.xml  { head :ok }
    end
  end
  
  def thumbnail
    @video_clip = VideoClip.find(params[:id])
    send_data @vidavee.file_thumbnail_medium(session[:vidavee],@video_clip.dockey), :filename => "clip#{@video_clip.id}.jpg", :type => 'image/jpeg' 
  end
end
