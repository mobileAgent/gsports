class TeamsController < BaseController

  auto_complete_for :team, :name
  skip_before_filter :verify_authenticity_token, :only => [:auto_complete_for_team_name, :auto_complete_for_team_league_name ]
  before_filter :admin_required, :only => [:index, :new, :create, :destroy]
  before_filter :admin_for_league_or_team, :only => [:edit, :update]
  skip_before_filter :gs_login_required, :only => [:show_public]
  after_filter :cache_control, :only => [:update, :create, :destroy]
  
  # GET /team
  # GET /team.xml
  def index
    if params[:league_id]
      @league = League.find(params[:league_id], :order => :name, :include => [:state])
      @teams = @league.teams(:include => [:state])
    else
      @teams = Team.find(:all, :order => :name, :include => [:state, :league])
    end
    
    respond_to do |format|
      format.html # index.haml
      format.xml  { render :xml => @teams }
    end
  end

  # GET /team/1
  # GET /team/1.xml
  def show
    team_id = params[:id]
    @team = Team.find(team_id)
    load_team_and_related_videos(@team)
    load_team_favorites(@team)
    respond_to do |format|
      format.html # show.haml
      format.xml  { render :xml => @team }
      format.js { render :xml => @team }
    end
  end

  # GET /teamname/:team_name
  def show_by_name
    @team = Team.find_by_name(params[:team_name])
    if (params[:nick])
      title_name = @team ? @team.title_name : params[:team_name]
      render :inline => title_name and return
        
    end

    if (@team)
      respond_to do |format|
        format.html { render :action => :show }
        format.xml  { render :xml => @team }
        format.js { render :xml => @team }
      end
    else
      respond_to do |format|
        format.html { render :controller => 'base', :action => 'site_index' }
        format.xml  { render :xml => '', :status => :unprocessable_entity }
        format.xml  { render :xml => '', :status => :unprocessable_entity }
      end
    end
  end

  # Renders the show action, but without current_user
  # and hence allows no further linking into the site.
  def show_public
    team_id = params[:id]
    @team = Team.find(team_id)
    load_team_and_related_videos(@team)
    load_team_favorites(@team)
    respond_to do |format|
      format.html { render :action => 'show' }
      format.xml  { render :xml => @team }
    end
  end

  # GET /team/new
  # GET /team/new.xml
  def new
    @team = Team.new
    if params[:league_id]
      @team.league= League.find(params[:league_id])
    end
    @leagues = League.all(:order => "name asc")
    respond_to do |format|
      format.html # new.haml
      format.xml  { render :xml => @team }
    end
  end

  # GET /team/1/edit
  def edit
    @team = Team.find(params[:id])
    unless ((current_user.team_staff? && current_user.team_id == @team.id ) ||
            current_user.admin?)
      flash[:notice] = "You don't have permission to edit that record"
      access_denied and return
    end
    @leagues = League.all(:order => "name asc")
  end

  # POST /team
  # POST /team.xml
  def create
    @team = Team.new(params[:team])

    respond_to do |format|
      if @team.save
        flash[:notice] = 'School info was successfully created.'
        format.html { redirect_to(current_user.admin? ? teams_url : team_path(@team)) }
        format.xml  { render :xml => @team, :status => :created, :location => @team }
      else
        @leagues = League.all(:order => "name asc")
        format.html { render :action => "new" }
        format.xml  { render :xml => @team.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /team/1
  # PUT /team/1.xml
  def update
    @team = Team.find(params[:id])
    unless ((current_user.team_staff? && current_user.team_id == @team.id ) ||
            current_user.admin?)
      flash[:notice] = "You don't have permission to edit that record"
      access_denied
    end

    if current_user.admin?
      params[:team][:league_name] ||= current_user.league_name
    else
      params[:team][:league_name] = current_user.league_name
    end
    
    @avatar = Photo.new(params[:avatar])
    @avatar.user_id = current_user.id
    if @avatar.save
      @team.avatar = @avatar
    end

    status = @team.update_attributes(params[:team])

    respond_to do |format|
      if status
        flash[:notice] = 'School info was successfully updated.'
        format.html { redirect_to(current_user.admin? ? teams_url : team_path(@team)) }
        format.xml  { head :ok }
      else
        @leagues = League.all(:order => "name asc")
        format.html { render :action => "edit" }
        format.xml  { render :xml => @team.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /team/1
  # DELETE /team/1.xml
  def destroy
    @team = Team.find(params[:id])
    @team.destroy

    respond_to do |format|
      format.html { redirect_to(teams_url) }
      format.xml  { head :ok }
    end
  end
  
  def auto_complete_for_team_league_name
    @leagues = League.find(:all, :conditions => ["LOWER(name) like ?", params[:team][:league_name].downcase + '%' ], :order => "name ASC", :limit => 10 )
    choices = "<%= content_tag(:ul, @leagues.map { |l| content_tag(:li, h(l.name)) }) %>"    
    render :inline => choices
  end

  protected

  def load_team_and_related_videos(team)
    if Team === team
      team_id = team.id
    else
      team_id = team.to_i
      team = Team.find(team_id)
    end

    @team_videos = Array.new
    @team_popular_videos = Array.new
    @team_clips_reels = Array.new

    if team.member? || team_id==1
      @team_videos = VideoAsset.for_team(team).all(:limit => 10, :order => 'updated_at DESC')
      @team_popular_videos = VideoAsset.for_team(team).all(:limit => 10, :order => 'view_count DESC')

      show_clips_reels = false 
      if show_clips_reels
        @team_clips_reels = VideoClip.for_team(team).find(:all, :limit => 10, :order => "video_clips.created_at DESC")
        @team_clips_reels << VideoReel.for_team(team).find(:all, :limit => 10, :order => "video_reels.created_at DESC")
        @team_clips_reels.flatten!
        @team_clips_reels.sort! { |a,b| b.created_at <=> a.created_at }
      end

      if @team_clips_reels.empty?
        load_team_and_related_videos(1) unless team_id==1
      end
    end

  end

  def load_team_favorites(team)
    if Team === team
      team_id = team.id
    else
      team_id = team.to_i
      team = Team.find(team_id)
    end

    photo_picks = Favorite.ftype('Photo').for_team_staff(team_id).map(){|f|Photo.find(f.favoritable_id)}
    @team_photo_picks = photo_picks.sort {|x,y| y.created_at <=> x.created_at}.first(5)
    #random_slice(photo_picks, 5)
    
    @player_title = 'Featured Videos'
    video_favorites = Favorite.ftypes('VideoAsset','VideoReel','VideoClip').for_team_staff(team_id)
    if(video_favorites.empty?)
      @player_title = 'Recent Uploads'
      @hide_recent_uploads = true
      video_picks = @team_videos.first(6) if @team_videos
    else
      video_favorites.sort! {|x,y| y.created_at <=> x.created_at}.first(6)
      video_picks = video_favorites.map(){|f|eval "#{f.favoritable_type}.find(f.favoritable_id)"}
    end
    @team_video_picks = video_picks.collect(&:dockey).join(",")
  end

  def random_slice(a, s)
    l=a.length-s
    p=(l>=0?rand(l+1):0);
    a[p..p+s-1];
  end


  def cache_control
    Rails.cache.delete('quickfind_states')
    Rails.cache.delete('quickfind_counties')
    Rails.cache.delete('quickfind_cities')
    Rails.cache.delete('quickfind_schools')
  end
  
end
