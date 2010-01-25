class RosterEntriesController < BaseController

  before_filter :except => [:show] do  |c| c.find_staff_scope(Permission::COACH) end

  skip_before_filter :verify_authenticity_token, :only => [:roster, :post ]

  sortable_attributes 'number', 'firstname', 'lastname', 'email', 'phone', 'position'


  def index
  end


  def show
  end


  def new
    @team_sport = TeamSport.new
  end


  def post
    @roster_entry = nil

    saved = false

    begin
      @roster_entry = RosterEntry.find(params[:id])

      unless current_user.can?(Permission::COACH, @roster_entry.team_sport)
        flash[:notice] = "You don't have permission to edit that record"
        access_denied and return
      end

      saved = @team_sport.update_attributes(params[:team_sport])

    rescue
      #it's new

      @roster_entry = RosterEntry.new(params[:roster_entry])

      unless current_user.can?(Permission::COACH, @roster_entry.team_sport)
        flash[:notice] = "You don't have permission to edit that record"
        access_denied and return
      end

      saved = @roster_entry.save

    end

    render :update do |page|
      if saved
        flashnow(page,'School info was successfully updated.')
      else
        #page.replace_html 'staff_summary', :text => 'zoom'
        flashnow(page,'Roster entry could not be updated.')
      end
    end

  end


  def create
  end


  def update
    @team_sport = TeamSport.find(params[:id])

    unless current_user.can?(Permission::COACH, @team_sport)
      flash[:notice] = "You don't have permission to edit that record"
      access_denied and return
    end

    @avatar = Photo.new(params[:avatar])
    @avatar.user_id = current_user.id
    if @avatar.save
      @team_sport.avatar = @avatar
    else
      flash[:notice] = 'Avatar was not created.'
    end

    if @team_sport.update_attributes(params[:team_sport])

      flash[:notice] = 'School info was successfully updated.'
      redirect_to team_sports_url
    else
      render :action => "edit"
    end
  end


  def destroy
    @roster_entry = RosterEntry.find(params[:id])

    unless current_user.can?(Permission::COACH, @roster_entry.team_sport)
      flash[:notice] = "You don't have permission to edit that record"
      access_denied and return
    end

    @roster_entry.destroy

    redirect_to(team_sports_url)
  end

  def roster
    @team_sport = TeamSport.find(params[:id])

    @roster_entry = RosterEntry.new()
    @roster_entry.access_group = @team_sport.access_group


    @roster = RosterEntry.roster(@team_sport.access_group).paginate(:all, :order => sort_order, :page => params[:page])




    render :layout => false
  end

end