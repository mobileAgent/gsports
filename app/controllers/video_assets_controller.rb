class VideoAssetsController < BaseController
  
  # Only admin can edit this table directly
  # Those just wishing to use the values, see vidapi_controller
  before_filter :admin_required, :except => [:show, :upload]
  before_filter :vidavee_login
  
  # GET /video_assets
  # GET /video_assets.xml
  def index
    
    # @video_assets = VideoAsset.find(:all)
    @pages, @video_assets = paginate :video_assets, :order => "created_at DESC"

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
      format.html # new.html.erb
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

end
