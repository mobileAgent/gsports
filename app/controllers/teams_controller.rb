class TeamsController < BaseController

  auto_complete_for :team, :name
  skip_before_filter :verify_authenticity_token, :only => [:auto_complete_for_team_name, :auto_complete_for_team_league_name ]
  before_filter :admin_required, :except => [:auto_complete_for_team_name, :show, :show_by_name, :show_public, :auto_complete_for_team_league_name ]
  skip_before_filter :gs_login_required, :only => [:show_public]
  after_filter :cache_control, :only => [:update, :create, :destroy]
  
  # GET /team
  # GET /team.xml
  def index
    if params[:league_id]
      @league = League.find(params[:league_id], :order => :name)
      @teams = @league.teams
    else
      @teams = Team.find(:all, :order => :name)
    end
    
    respond_to do |format|
      format.html # index.haml
      format.xml  { render :xml => @teams }
    end
  end

  # GET /team/1
  # GET /team/1.xml
  def show
    @team = Team.find(params[:id])
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
      render :inline => @team.title_name and return
    end
    
    respond_to do |format|
      format.html { render :action => :show }
      format.xml  { render :xml => @team }
      format.js { render :xml => @team }
    end
  end
  
  def show_public
    @team = Team.find(params[:id])

    respond_to do |format|
      format.html # show.haml
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
    respond_to do |format|
      format.html # new.haml
      format.xml  { render :xml => @team }
    end
  end

  # GET /team/1/edit
  def edit
    @team = Team.find(params[:id])
  end

  # POST /team
  # POST /team.xml
  def create
    @team = Team.new(params[:team])

    respond_to do |format|
      if @team.save
        flash[:notice] = 'Team was successfully created.'
        format.html { redirect_to(current_user.admin? ? teams_url : team_path(@team)) }
        format.xml  { render :xml => @team, :status => :created, :location => @team }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @team.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /team/1
  # PUT /team/1.xml
  def update
    @team = Team.find(params[:id])

    respond_to do |format|
      if @team.update_attributes(params[:team])
        flash[:notice] = 'Team was successfully updated.'
        format.html { redirect_to(current_user.admin? ? teams_url : team_path(@team)) }
        format.xml  { head :ok }
      else
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

  def cache_control
    Rails.cache.delete('quickfind_states')
    Rails.cache.delete('quickfind_counties')
    Rails.cache.delete('quickfind_cities')
  end
  
end
