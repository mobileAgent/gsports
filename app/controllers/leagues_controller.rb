class LeaguesController < BaseController

  SHOW_CLIPS_REELS = false 
  PHOTO_GALLERY_SIZE = 5
  
  auto_complete_for :league, :name
  before_filter :admin_required, :only => [:create, :index, :new, :destroy]
  #before_filter :admin_for_league_or_team, :only => [:edit, :update]
  after_filter :cache_control, :only => [:create, :update, :destroy]
  
  # GET /league
  # GET /league.xml
  def index
    @leagues = League.find(:all, :order => :name)

    respond_to do |format|
      format.html # index.haml
      format.xml  { render :xml => @leagues }
    end
  end

  # GET /league/1
  # GET /league/1.xml
  def show
    @league = League.find(params[:id])
    
    load_related_videos(@league)
    load_favorites(@league)

    respond_to do |format|
      format.html # show.haml
      format.xml  { render :xml => @league }
    end
  end

  # GET /league/new
  # GET /league/new.xml
  def new
    @league = League.new

    respond_to do |format|
      format.html # new.haml
      format.xml  { render :xml => @league }
    end
  end

  # GET /league/1/edit
  def edit
    @league = League.find(params[:id])
    unless ((current_user.league_staff? && current_user.league_id == @league.id ) ||
            current_user.admin?)
      access_denied and return
    end
  end

  # POST /league
  # POST /league.xml
  def create
    @league = League.new(params[:league])

    respond_to do |format|
      if @league.save
        flash[:notice] = 'League was successfully created.'
        format.html { redirect_to(current_user.admin? ? leagues_url : league_path(@league)) }
        format.xml  { render :xml => @league, :status => :created, :location => @league }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @league.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /league/1
  # PUT /league/1.xml
  def update
    @league = League.find(params[:id])
    unless ((current_user.league_staff? && current_user.league_id == @league.id ) ||
            current_user.admin?)
      access_denied and return
    end
    
    @avatar = Photo.new(params[:avatar])
    @avatar.user_id = current_user.id
    if @avatar.save
      @league.avatar = @avatar
    end

    respond_to do |format|
      if @league.update_attributes(params[:league])
        flash[:notice] = 'League was successfully updated.'
        format.html { redirect_to(current_user.admin? ? leagues_url : league_path(@league)) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @league.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /league/1
  # DELETE /league/1.xml
  def destroy
    @league = League.find(params[:id])
    @league.destroy

    respond_to do |format|
      format.html { redirect_to(leagues_url) }
      format.xml  { head :ok }
    end
  end

  protected
  
  
  
  def load_related_videos(league)
    if League === league
      league_id = league.id
    else
      league_id = league.to_i
      league = League.find(league_id)
    end
    
    
    @league_videos = VideoAsset.for_league(@league).all(:limit => 10, :order => 'updated_at DESC')
    @league_popular_videos = VideoAsset.for_league(@league).all(:limit => 10, :order => 'view_count DESC')

    @recent_uploads = @league_videos unless @league_videos.empty?

    if @league_videos.empty?
      @league_videos << VideoAsset.for_league(league).all(:limit => 10, :order => 'updated_at DESC')
      @league_popular_videos << VideoAsset.for_league(league).all(:limit => 10, :order => 'view_count DESC')
      if !@league_videos.empty?
        @player_title = 'Games played in #{@league.name}'
      end
    end      

    @league_videos.flatten!
    @league_popular_videos.flatten!
    
    @league_clips_reels = Array.new
    load_clips_reels(league) if SHOW_CLIPS_REELS
  end

  def load_clips_reels(league)
    if League === league
      league_id = league.id
    else
      league_id = league.to_i
      league = League.find(league_id)
    end
    
    @league_clips_reels = VideoClip.for_league(@league).find(:all, :limit => 10, :order => "video_clips.created_at DESC")
    @league_clips_reels << VideoReel.for_league(@league).find(:all, :limit => 10, :order => "video_reels.created_at DESC")

    if @league_clips_reels.empty?
      return load_clips_reels(1) unless league_id==1
    end
    
    @league_clips_reels.flatten!
    @league_clips_reels.sort! { |a,b| a.created_at <=> b.created_at }
    
    @league_clips_reels
  end

  def load_favorites(league)
    if League === league
      league_id = league.id
    else
      league_id = league.to_i
      league = League.find(league_id)
    end

    @league_photo_picks = Array.new
    @league_video_picks = Array.new

    load_photo_gallery(league)
    #random_slice(photo_picks, 5)
    
    @player_title = 'Featured Videos'
    video_favorites = Favorite.ftypes('VideoAsset','VideoReel','VideoClip').for_league_staff(league_id)
    if(video_favorites.empty?)
      @player_title = 'Recent Uploads'
      @hide_recent_uploads = true
      video_picks = @recent_uploads if @recent_uploads && !@recent_uploads.empty?
    else
      video_favorites.sort! {|x,y| y.created_at <=> x.created_at}.first(6)
      video_picks = video_favorites.map(){|f|eval "#{f.favoritable_type}.find(f.favoritable_id)"}
    end
    unless video_picks.nil? || video_picks.empty?
      @league_video_picks = video_picks.first(6).collect(&:dockey).join(",") 
    end
  end

  def load_photo_gallery(league, index=0)
    if League === league
      league_id = league.id
    else
      league_id = league.to_i
      league = League.find(league_id)
    end
    
    photo_picks = Favorite.ftype('Photo').for_league_staff(league_id).map(){|f|Photo.find(f.favoritable_id)}
    total = photo_picks.nil? ? 0 : photo_picks.size
    if index > total
      index = total < PHOTO_GALLERY_SIZE ? 0 : total - PHOTO_GALLERY_SIZE;
    elsif index < 0
      index = 0
    end
    @league_photo_index = index
    @league_photo_total = total
    @league_photo_picks = photo_picks.sort {|x,y| y.created_at <=> x.created_at}[index,index+PHOTO_GALLERY_SIZE] unless photo_picks.nil?
  end

  

  def cache_control
    Rails.cache.delete('quickfind_leagues')
  end
  
end
