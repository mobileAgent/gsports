class VideoReelsController < BaseController
  
  # GET /video_reels
  # GET /video_reels.xml
  def index
    @video_reels = VideoReel.find(:all)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @video_reels }
    end
  end

  # GET /video_reels/1
  # GET /video_reels/1.xml
  def show
    @video_reel = VideoReel.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @video_reel }
    end
  end

  # GET /video_reels/new
  # GET /video_reels/new.xml
  def new
    @video_reel = VideoReel.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @video_reel }
    end
  end

  # GET /video_reels/1/edit
  def edit
    @video_reel = VideoReel.find(params[:id])
  end

  # POST /video_reels
  # POST /video_reels.xml
  def create
    @video_reel = VideoReel.new(params[:video_reel])

    respond_to do |format|
      if @video_reel.save
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
      if @video_reel.update_attributes(params[:video_reel])
        flash[:notice] = 'VideoReel was successfully updated.'
        format.html { redirect_to(@video_reel) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @video_reel.errors, :status => :unprocessable_entity }
      end
    end
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
  end
end
