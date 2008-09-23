class VideoAssetsController < BaseController
  include Viewable
  include ActiveMessaging::MessageSender
  publishes_to :push_video_files

  skip_before_filter :verify_authenticity_token, :only => [:auto_complete_for_video_asset_home_team_name,
                                                           :auto_complete_for_video_asset_visiting_team_name,
                                                           :auto_complete_for_video_asset_team_name,
                                                           :auto_complete_for_video_asset_league_name,
                                                           :auto_complete_for_video_asset_sport ]
  
  session :cookie_only => false, :only => [:swfupload]
  protect_from_forgery :except => [:swfupload ]
  verify :method => :post, :only => [ :save_video, :swfupload ]
  after_filter :cache_control, :only => [:create, :update, :destroy]
  after_filter :expire_games_of_the_week, :only => [:destroy]
  before_filter :find_user, :only => [:index, :show, :new, :edit ]
  uses_tiny_mce(:options => AppConfig.narrow_mce_options.merge({:width => 530}),
                :only => [:show])

  def images
    redirect_to "/players/images/#{params[:id]}.#{params[:format]}" and return
  end

  # GET /video_assets
  # GET /video_assets.xml
  def index

    @user = params[:user_id] ? User.find(params[:user_id]) : current_user
    
    # Only admin, league and team staff have video_assets
    # If user isn't one of those, redirect to video_clips
    if(!current_user.admin? && !current_user.team_staff? && !current_user.league_staff?)
      redirect_to user_video_clips_path(@user) and return
    end

    # Team staff can only manage their own accounts
    if (current_user.team_staff? &&
        ! User.team_staff_ids(current_user.team_id).member?(current_user.id))
      redirect_to_user_video_clips_path(@user) and return
    end
    
    # Leagu staff can only manage their own accounts
   if (current_user.league_staff? &&
       ! User.league_staff_ids(current_user.league_id).member?(current_user.id))
     redirect_to_user_video_clips_path(@user) and return
   end

    cond = Caboose::EZ::Condition.new
    cond.user_id == @user.id
    if params[:tag_name]    
      cond.append ['tags.name = ?', params[:tag_name]]
    end
    #cond.append ['video_status = ?','ready']
    
    @video_assets = VideoAsset.paginate(:conditions => cond.to_sql, :page => params[:page], :order => "created_at DESC", :include => :tags)
    @tags = VideoAsset.tags_count :user_id => @user.id, :limit => 20

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @video_assets }
    end
  end

  # GET /video_assets/1
  # GET /video_assets/1.xml
  def show
    @video_asset = VideoAsset.find(params[:id])
    update_view_count(@video_asset)
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @video_asset }
    end
  rescue ActiveRecord::RecordNotFound
    flash[:notice] = 'That video could not be found.'
    redirect_to url_for({ :controller => "search", :action => "my_videos" })
  end

  # GET /video_assets/new
  # GET /video_assets/new.xml
  def new
    unless current_user.can_upload?
      flash[:notice] = "You don't have permission to upload videos"
      redirect_to url_for({ :controller => "search", :action => "my_videos" }) and return
    end
    
    @video_asset = VideoAsset.new

    # Set default team name in the home team slot to help them figure it out
    unless (current_user.admin? || current_user.league_staff?)
      @video_asset.home_team_name = current_user.team.name
    end

    respond_to do |format|
      format.html # new.html.haml
      format.xml  { render :xml => @video_asset }
    end
  end

  # GET /video_assets/1/edit
  def edit
    @video_asset = VideoAsset.find(params[:id])
    unless (current_user.can_edit?(@video_asset))
      @video_asset = nil
      flash[:notice] = "You don't have permission edit that video"
      redirect_to url_for({ :controller => "search", :action => "my_videos" }) and return
    end
  rescue ActiveRecord::RecordNotFound
    flash[:notice] = 'That video could not be found.'
    redirect_to url_for({ :controller => "search", :action => "my_videos" })
  end

  # POST /video_assets
  # POST /video_assets.xml
  def create
    
    unless current_user.can_upload?
      flash[:notice] = "You don't have permission to upload video"
      redirect_to url_for({ :controller => "search", :action => "my_videos" }) and return
    end
    
    gd = params[:video_asset][:game_date] 
    if (gd && gd.length > 0 && gd.length <= 7) # yyyy-mm
      params[:video_asset][:game_date] += '-01'
      params[:video_asset][:ignore_game_day] = true
    end
    @video_asset = VideoAsset.new(params[:video_asset])
    @video_asset.video_status = 'unknown'
      
    respond_to do |format|
      if @video_asset.save!
        flash[:notice] = 'VideoAsset was successfully created.'
        format.html { redirect_to(@video_asset) }
        format.xml  { render :xml => @video_asset, :status => :created, :location => @video_asset }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @video_asset.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /video_assets/1
  # PUT /video_assets/1.xml
  def update
    @video_asset = VideoAsset.find(params[:id])
    unless (current_user.can_edit?(@video_asset))
      @video_asset = nil
      flash[:notice] = "You don't have permission edit that video"
      redirect_to url_for({ :controller => "search", :action => "my_videos" }) and return
    end

    respond_to do |format|
      @video_asset.tag_with(params[:tag_list] || '') 
      @video_asset = add_team_and_league_relations(@video_asset,params)
      gd = params[:video_asset][:game_date]
      params[:video_asset][:ignore_game_month] = false
      params[:video_asset][:ignore_game_day] = false
      params[:video_asset][:game_date_str] = gd
      if (gd && gd.length > 0 && gd.length == 4) # yyyy
        params[:video_asset][:game_date] += "-01"
        params[:video_asset][:ignore_game_month] = true
      end
      if (gd && gd.length > 0 && gd.length == 7) # yyyy-mm
        params[:video_asset][:game_date] += '-01'
        params[:video_asset][:ignore_game_day] = true
      end
        
      if @video_asset.update_attributes(params[:video_asset])
        flash[:notice] = 'VideoAsset was successfully updated.'
        format.html { redirect_to(@video_asset) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @video_asset.errors, :status => :unprocessable_entity }
      end
    end
  rescue ActiveRecord::RecordNotFound
    flash[:notice] = 'That video could not be found.'
    redirect_to url_for({ :controller => "search", :action => "my_videos" })
  end

  # DELETE /video_assets/1
  # DELETE /video_assets/1.xml
  def destroy
    @video_asset = VideoAsset.find(params[:id])
    unless (current_user.can_edit?(@video_asset))
      flash[:notice] = "You don't have permission delete that video"
      redirect_to url_for({ :controller => "search", :action => "my_videos" })  and return
    end
    
    @video_asset.destroy

    respond_to do |format|
      format.html { redirect_to(video_assets_url) }
      format.xml  { head :ok }
      format.js
    end
  rescue ActiveRecord::RecordNotFound
    flash[:notice] = 'That video could not be found.'
    redirect_to url_for({ :controller => "search", :action => "my_videos" })
  end

  # POST /video_assets/swfupload comes from the video_uploader.js 
  def swfupload
    f = params[:Filedata] # the tmp file
    fpath = VideoAsset.move_upload_to_repository(f,params[:Filename])
    @video = VideoAsset.new :uploaded_file_path => fpath, :title => 'Upload in Progress', :user_id => current_user.id
    @video.save!
    render :text => @video.id
  rescue
    render :text => "Error saving file"
  end
  
  # POST /vidapi/save_video (the rest of the form after the swfupload)
  def save_video
    if params[:hidFileID]
      @video_asset = VideoAsset.find(params[:hidFileID])
      @video_asset.attributes= params[:video_asset]
    else
      @video_asset = VideoAsset.new params[:video_asset]
      # TODO: check for a fallback non-swf file upload and add it here
    end

    # Set up things that don't come naturally from the form
    @video_asset.video_status = 'saving'
    @video_asset.user_id = current_user.id
    @video_asset = add_team_and_league_relations(@video_asset,params)
    
    @video_asset.tag_with(params[:tag_list] || '') 

    if @video_asset.save!
      publish(:push_video_files,"#{@video_asset.id}")
      flash[:notice] = "Your video is being procesed. It may be several minutes before it appears in your gallery"
      render :action=>:upload_success
    else
      flash[:notice] = "There was a problem with the video"
      render :action=>:upload
    end
  end

  def upload_success
  end
  
  auto_complete_for :video_asset, :sport

  def auto_complete_for_video_asset_team_name
    render :inline => auto_complete_team_field(params[:video_asset][:team_name])
  end
  
  def auto_complete_for_video_asset_home_team_name
    render :inline => auto_complete_team_field(params[:video_asset][:home_team_name])
  end
  
  def auto_complete_for_video_asset_visiting_team_name
    render :inline => auto_complete_team_field(params[:video_asset][:visiting_team_name])
  end

  def auto_complete_for_video_asset_league_name
    @leagues = League.find(:all, :conditions => ["LOWER(name) like ?", params[:video_asset][:league_name].downcase + '%' ], :order => "name ASC", :limit => 10 )
    choices = "<%= content_tag(:ul, @leagues.map { |l| content_tag(:li, h(l.name)) }) %>"    
    render :inline => choices
  end

  private

  def auto_complete_team_field(team_name_start)
    @teams = Team.find(:all, :conditions => ["LOWER(name) like ?", team_name_start.downcase + '%' ], :order => "name ASC", :limit => 10 )
    "<%= content_tag(:ul, @teams.map { |t| content_tag(:li, h(t.name)) }) %>"    
  end

  def add_team_and_league_relations(video_asset,params)
    
    # Set up team (should only come from admin form)
    admin_set_team = false
    if(current_user.admin? && !params[:video_asset][:team_name].blank?)
      video_asset.team_name= params[:video_asset][:team_name]
      # Transfer ownership to the admin
      admin = User.team_admin(video_asset.team_id)
      video_asset.user_id = admin[0].id if (admin && admin.any?)
      admin_set_team = true
    else
      video_asset.team= current_user.team
    end
    
    # Set up league (should only come from admin form)
    if(current_user.admin? && !params[:video_asset][:league_name].blank?)
      video_asset.league_name= params[:video_asset][:league_name]
      # Transfer ownership to the admin
      admin = User.league_admin(video_asset.league_id)
      video_asset.user_id = admin[0].id if (admin && admin.any?)
      if (video_asset.team_id? && admin_set_team)
        video_asset.team.league_id= video_asset.league_id
      end
    else
      video_asset.league_id= current_user.league_id
    end
    video_asset
  end

  protected

  def find_user
    @user = params[:user_id] ? User.find(params[:user_id]) : current_user
  end

  def cache_control
    Rails.cache.delete('quickfind_sports');
    Rails.cache.delete('quickfind_seasons');
  end

end
