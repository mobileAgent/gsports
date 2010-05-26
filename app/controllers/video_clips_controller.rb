class VideoClipsController < BaseController
  include Viewable
  
  skip_before_filter :verify_authenticity_token, :only => [:create]
  before_filter :find_user, :only => [:index, :show, :new, :edit ]

  uses_tiny_mce(:options => AppConfig.narrow_mce_options.merge({:width => 530}),
                :only => [:show])
  
  after_filter :expire_games_of_the_week, :only => [:destroy]

  skip_before_filter :gs_login_required, :only => [ :show ]
  
  # GET /video_clips
  # GET /video_clips.xml
  def index
    
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
    @user = params[:user_id] ? User.find(params[:user_id]) : current_user
    @video_clip = VideoClip.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    flash[:notice] = 'That clip could not be found.'
    redirect_to url_for({ :controller => "search", :action => "my_videos" })
  end

  def share
    video = VideoClip.find(params[:id])
    video.share!
    redirect_to new_message_path(:shared_access_id => video.shared_access_id) 
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
      @video_clip.video_length = params[:video_length]
      @video_clip.description = params[:description]
      @video_clip.public_video = params[:public_video] || true
      @video_clip.dockey = params[:dockey]
      if(params[:video_asset_id] && params[:video_asset_id].length > 10)
        @video_clip.video_asset_id = VideoAsset.find_by_dockey(params[:video_asset_id]).id
      elsif params[:video_asset_id]
        @video_clip.video_asset_id = params[:video_asset_id]
      end
      @video_clip.public_video = params[:public_video]
      @video_clip.tag_with(params[:tags]) if (params[:tags])
    else
      @video_clip = VideoClip.new(params[:video_clip])
      @video_clip.tag_with(params[:tag_list] || '') 
    end
    
    #saved =
    @video_clip.save!
    saved = true

    #if saved
      if @video_clip.video_asset.gamex_league_id
        @access_item = AccessItem.new()
        @access_item.item = @video_clip
        gamex_user = GamexUser.for_user_and_league(current_user.id, @video_clip.video_asset.gamex_league_id).first
        #gamex_user = GamexUser.for_user_and_league(current_user, @video_clip.video_asset.league).first
        #gamex_user = GamexUser.find(@video_clip.video_asset.gamex_league_id).first
        @access_item.access_group_id = gamex_user.access_group_id
        @access_item.save!
      end
    #end


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
  
  protected
  
  def find_user
    @user = params[:user_id] ? User.find(params[:user_id]) : current_user
  end

end
