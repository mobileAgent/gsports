class TeamSportsController < BaseController

  before_filter :except => [:show] do  |c| c.find_staff_scope(Permission::COACH) end


  sortable_attributes 'team_sports.name', 'team_sports.id', 'teams.name'


  def index
    conditions = {}
    
    if !current_user.admin?
      conditions = { :id => @scopes.collect(&:id) }
    end

    @team_sports = TeamSport.paginate(:all, :order => sort_order,
      :conditions => conditions,
      :page => params[:page])

  end


  def show
    @team_sport = TeamSport.find(params[:id])
    load_team_and_related_videos(@team)
    load_team_favorites(@team)
    @header_post = Post.admin_team_headers.first

    respond_to do |format|
      format.html # show.haml
      format.xml  { render :xml => @team }
      format.js { render :xml => @team }
    end
  end


  def new
    @team_sport = TeamSport.new
  end


  def edit
    @team_sport = TeamSport.find(params[:id])

    unless current_user.can?(Permission::COACH, @team_sport)
      flash[:notice] = "You don't have permission to edit that record"
      access_denied and return
    end

    @leagues = League.all(:order => "name asc")
  end


  def create
    @team_sport = TeamSport.new(params[:team_sport])

    if @team_sport.save
      flash[:notice] = 'Sport was successfully created.'
      redirect_to team_sports_url
    else
      render :action => "new"
    end
  end


  def update
    @team_sport = TeamSport.find(params[:id])

    unless current_user.can?(Permission::COACH, @team_sport)
      flash[:notice] = "You don't have permission to edit that record"
      access_denied and return
    end

    if @team_sport.update_attributes(params[:team_sport])
      flash[:notice] = 'School info was successfully updated.'
      redirect_to team_sports_url
    else
      render :action => "edit"
    end
  end


  def destroy
    @team_sport = TeamSport.find(params[:id])

    unless current_user.can?(Permission::COACH, @team_sport)
      flash[:notice] = "You don't have permission to edit that record"
      access_denied and return
    end

    @team_sport.destroy

    redirect_to(team_sports_url)
  end



end