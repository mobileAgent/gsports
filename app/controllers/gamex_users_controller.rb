class GamexUsersController < BaseController

  auto_complete_for :gamex_user, :league_name
  skip_before_filter :verify_authenticity_token, :only => [:auto_complete_for_gamex_user_league_name ]
  #before_filter :team_staff_or_admin, :except => [:auto_complete_for_access_group_team ]
  
  
  before_filter :admin_required #, :only=>[:new, :create, :update, :remove]
  
  #before_filter :instantiate_team_param, :only=>[:create, :update]
  #after_filter :serialize_team_param, :only=>[:create, :update]
  #before_filter :fix_team_name, :only=>[:create, :update]
  
  before_filter :fix_league_name, :only=>[:create, :update]
  
  
  sortable_attributes 'gamex_users.id', 'gamex_users.league_id', 'leagues.name'



  def index
    @gamex_users = GamexUser.paginate(:all, :order => sort_order, :page=>params[:page])  

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @gamex_users }
    end
  end

  def show
    @gamex_user = GamexUser.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @gamex_user }
    end
  end

  def new
    @gamex_user = GamexUser.new params[:gamex_user]
    @gamex_users = GamexUser.find(:all, :conditions => { :user_id => @gamex_user.user_id } )
    

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @gamex_user }
    end
  end

  def edit
    @gamex_user = GamexUser.find(params[:id])
    @gamex_users = GamexUser.find(:all, :conditions => { :user_id => @gamex_user.user_id } )
  end

  def create
    @gamex_user = GamexUser.new(params[:gamex_user])

    respond_to do |format|
      if @gamex_user.save
        flash[:notice] = 'GamexUser was successfully created.'
        format.html { redirect_to(@gamex_user) }
        format.xml  { render :xml => @gamex_user, :status => :created, :location => @gamex_user }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @gamex_user.errors, :status => :unprocessable_entity }
      end
    end
  end

  def update
    @gamex_user = GamexUser.find(params[:id])

    respond_to do |format|
      if @gamex_user.update_attributes(params[:gamex_user])
        flash[:notice] = 'GamexUser was successfully updated.'
        format.html { redirect_to(@gamex_user) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @gamex_user.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    @gamex_user = GamexUser.find(params[:id])
    @gamex_user.destroy

    respond_to do |format|
      format.html { redirect_to(gamex_users_url) }
      format.xml  { head :ok }
    end
  end
  
  
  
  def auto_complete_for_gamex_user_league_name
    @teams = []
    if params[:gamex_user] && params[:gamex_user][:league_name]
      conditions = ["LOWER(name) like ?", params[:gamex_user][:league_name].downcase + '%' ]
      @teams = League.find(:all, :conditions => conditions, :order => "name ASC", :limit => 10)
    end
    choices = "<%= content_tag(:ul, @teams.map { |t| content_tag(:li, h(t.name)) }) %>"    
    render :inline => choices
  end
  
  
  
  def fix_league_name
    if params[:gamex_user]
      league_name = params[:gamex_user][:league_name]
      if league_name
        league = League.find(:first, :conditions=>{ :name=>league_name }) 
        params[:gamex_user][:league_id] = league.id
      end
      params[:gamex_user].delete :league_name #[:team] = nil
      #params[:access_group][:team_name] = nil
    end
  end
  
  
  
  
  
  
  
  
  
end
