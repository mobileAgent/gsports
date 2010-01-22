class RosterEntriesController < BaseController

  before_filter :except => [:show] do  |c| c.find_staff_scope(Permission::COACH) end

  skip_before_filter :verify_authenticity_token, :only => [:post ]

  sortable_attributes 'roster_entries.number', 'roster_entries.firstname', 'roster_entries.lastname', 'roster_entries.email', 'roster_entries.phone', 'roster_entries.position'


  def index
  end


  def show
  end


  def new
    @team_sport = TeamSport.new
  end


  def post
    @roster_entry = nil
    begin
      @roster_entry = RosterEntry.find(params[:id])

      unless current_user.can?(Permission::COACH, @roster_entry.team_sport)
        flash[:notice] = "You don't have permission to edit that record"
        access_denied and return
      end

      if @team_sport.update_attributes(params[:team_sport])

        flash[:notice] = 'School info was successfully updated.'
        redirect_to team_sports_url
      else
        render :action => "edit"
      end

    rescue
      #it's new

      @roster_entry = RosterEntry.new(params[:roster_entry])

      unless current_user.can?(Permission::COACH, @roster_entry.team_sport)
        flash[:notice] = "You don't have permission to edit that record"
        access_denied and return
      end

      if @roster_entry.save

        render :update do |page|
          #page.replace_html 'staff_summary', :text => 'zoom'
          flashnow(page,'Roster entry was added created.')
          page.call 'gs.team_sports.open_panel', @roster_entry.team_sport.id
        end

      else
        render :action => "new"
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

end