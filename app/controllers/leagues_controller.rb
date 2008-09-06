class LeaguesController < BaseController

  auto_complete_for :league, :name
  before_filter :admin_required, :only => [:create, :index, :new, :destroy]
  before_filter :admin_for_league_or_team, :only => [:edit, :update]
  after_filter :cache_control, :only => [:create, :update, :delete]
  
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
    @league_popular_videos = VideoAsset.for_league(@league).all(:limit => 10, :order => 'view_count DESC')

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

  def cache_control
    Rails.cache.delete('quickfind_leagues')
  end
  
end
