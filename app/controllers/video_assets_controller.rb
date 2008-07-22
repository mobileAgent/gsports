class VideoAssetsController < BaseController
  
  include ActiveMessaging::MessageSender
  publishes_to :push_video_files

  before_filter :login_required
  before_filter :vidavee_login
  skip_before_filter :verify_authenticity_token, :only => [:auto_complete_for_video_asset_home_team_name,
                                                           :auto_complete_for_video_asset_visiting_team_name,
                                                           :auto_complete_for_video_asset_sport ]
  
  session :cookie_only => false, :only => [:swfupload]
  protect_from_forgery :except => [:swfupload ]
  verify :method => :post, :only => [ :save_video, :swfupload ]

  # GET /video_assets
  # GET /video_assets.xml
  def index
    
    @pages, @video_assets = paginate :video_assets, :conditions => [ "video_status = 'ready'" ], :order => "title ASC"

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @video_assets }
    end
  end

  # GET /video_assets/1
  # GET /video_assets/1.xml
  def show
    @video_asset = VideoAsset.find(params[:id])
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @video_asset }
    end
  end

  # GET /video_assets/new
  # GET /video_assets/new.xml
  def new
    @video_asset = VideoAsset.new

    respond_to do |format|
      format.html # new.html.haml
      format.xml  { render :xml => @video_asset }
    end
  end

  # GET /video_assets/1/edit
  def edit
    @video_asset = VideoAsset.find(params[:id])
  end

  # POST /video_assets
  # POST /video_assets.xml
  def create
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

    respond_to do |format|
      @video_asset.tag_with(params[:tag_list] || '') 
      if @video_asset.update_attributes(params[:video_asset])
        flash[:notice] = 'VideoAsset was successfully updated.'
        format.html { redirect_to(@video_asset) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @video_asset.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /video_assets/1
  # DELETE /video_assets/1.xml
  def destroy
    @video_asset = VideoAsset.find(params[:id])
    @video_asset.destroy

    respond_to do |format|
      format.html { redirect_to(video_assets_url) }
      format.xml  { head :ok }
    end
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

    logger.debug "********** Params for va = #{params[:video_asset]} , object is #{@video_asset.inspect}, valid is #{@video_asset.valid?}"

    # Set up things that don't come naturally from the form
    @video_asset.video_status = 'saving'
    @video_asset.user_id = current_user.id
    @video_asset.team= current_user.team
    @video_asset.league= current_user.team.league
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
  
  def auto_complete_for_video_asset_home_team_name
    render :inline => auto_complete_team_field(params[:video_asset][:home_team_name])
  end
  
  def auto_complete_for_video_asset_visiting_team_name
    render :inline => auto_complete_team_field(params[:video_asset][:visiting_team_name])
  end

  private

  def auto_complete_team_field(team_name_start)
    @teams = Team.find(:all, :conditions => ["LOWER(name) like ?", team_name_start.downcase + '%' ], :order => "name ASC", :limit => 10 )
    "<%= content_tag(:ul, @teams.map { |t| content_tag(:li, h(t.name)) }) %>"    
  end
  
end
