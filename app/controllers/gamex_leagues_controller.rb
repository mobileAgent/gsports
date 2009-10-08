class GamexLeaguesController < BaseController

  auto_complete_for :gamex_league, :league_name
  skip_before_filter :verify_authenticity_token, :only => [:auto_complete_for_gamex_league_league_name ]
  #before_filter :team_staff_or_admin, :except => [:auto_complete_for_access_group_team ]


  before_filter :admin_required #, :only=>[:new, :create, :update, :remove]

  #before_filter :instantiate_team_param, :only=>[:create, :update]
  #after_filter :serialize_team_param, :only=>[:create, :update]
  #before_filter :fix_team_name, :only=>[:create, :update]

  before_filter :fix_league_name, :only=>[:create, :update]


  before_filter :admin_required, :only=>[:new, :create, :update, :remove]

  sortable_attributes 'gamex_leagues.id', 'gamex_leagues.league_id', 'leagues.name', 'gamex_leagues.release_date'



  def index
    @gamex_leagues = GamexLeague.paginate(:all, :order => sort_order, :page=>params[:page])

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @gamex_leagues }
    end
  end

  def show
    @gamex_league = GamexLeague.find(params[:id])
    @gamex_league.disperse_release_time()

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @gamex_league }
    end
  end

  def new
    @gamex_league = GamexLeague.new params[:gamex_user]


    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @gamex_league }
    end
  end

  def edit
    @gamex_league = GamexLeague.find(params[:id])
    @gamex_league.disperse_release_time()
  end

  def create
    @gamex_league = GamexLeague.new(params[:gamex_league])
    respond_to do |format|
      if @gamex_league.save
        flash[:notice] = 'GamexLeague was successfully created.'

        format.html { redirect_to(@gamex_league) }
        format.xml  { render :xml => @gamex_league, :status => :created, :location => @gamex_league }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @gamex_league.errors, :status => :unprocessable_entity }
      end
    end
  end

  def update
    @gamex_league = GamexLeague.find(params[:id])
    respond_to do |format|
      if @gamex_league.update_attributes(params[:gamex_league])
        flash[:notice] = 'GamexUser was successfully updated.'
        format.html { redirect_to(@gamex_league) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @gamex_league.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    @gamex_league = GamexLeague.find(params[:id])
    @gamex_league.destroy

    respond_to do |format|
      format.html { redirect_to('/gamex_leagues') }
      format.xml  { head :ok }
    end
  end


  def auto_complete_for_gamex_league_league_name
    @teams = []
    if params[:gamex_league] && params[:gamex_league][:league_name]
      conditions = ["LOWER(name) like ?", params[:gamex_league][:league_name].downcase + '%' ]
      @teams = League.find(:all, :conditions => conditions, :order => "name ASC", :limit => 10)
    end
    choices = "<%= content_tag(:ul, @teams.map { |t| content_tag(:li, h(t.name)) }) %>"
    render :inline => choices
  end



  def fix_league_name
    if params[:gamex_league]
      league_name = params[:gamex_league][:league_name]
      if league_name
        league = League.find(:first, :conditions=>{ :name=>league_name })
        params[:gamex_league][:league_id] = league.id
      end
      params[:gamex_league].delete :league_name #[:team] = nil
      #params[:access_group][:team_name] = nil
    end
  end











end
