class RosterEntriesController < BaseController

  before_filter :except => [:show] do  |c| c.find_staff_scope(Permission::COACH) end

  skip_before_filter :verify_authenticity_token, :only => [:roster, :post ]

  sortable_attributes 'id', 'number', 'firstname', 'lastname', 'email', 'phone', 'position'


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
    msg = ''

    begin
      @roster_entry = RosterEntry.find(params[:roster_entry][:id])

      if current_user.can?(Permission::COACH, @roster_entry.team_sport)
        saved = @roster_entry.update_attributes(params[:roster_entry])
      else
        msg = "You don't have permission to edit that record"
      end

    rescue
      #it's new

      @roster_entry = RosterEntry.new(params[:roster_entry])

      if current_user.can?(Permission::COACH, @roster_entry.team_sport)
        saved = @roster_entry.save
      else
        msg = "You don't have permission to edit that record"
      end

    end

    render :update do |page|
      if saved
        flashnow(page,"Roster entry was successfully updated.")
        page.call 'gs.team_sports.sort_row', "/roster_entries/roster/#{@roster_entry.team_sport.id}?order=descending&sort=id"

        if params[:skip_match_dialog].nil? && @roster_entry.user_id.nil? && !@roster_entry.match_users().empty?
          page.call 'gs.team_sports.match_user', @roster_entry.id
        end

        if @roster_entry.send_invite && @roster_entry.email && !@roster_entry.email.empty?
          UserNotifier.deliver_roster_invite({:to=>@roster_entry, :from=>current_user})
        
        elsif @roster_entry.user_id
          access = AccessUser.for(@roster_entry.user, @roster_entry.access_group)
          if access.empty?
            au = AccessUser.new()
            au.user = @roster_entry.user
            au.access_group = @roster_entry.access_group
            au.save!
          end

        end

      else
        #page.replace_html 'staff_summary', :text => 'zoom'
        flashnow(page,"Roster entry could not be updated.")
        flashnow(page,msg,'error')
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

    #redirect_to(team_sports_url)

    respond_to do |format|
      format.html { redirect_to(team_sports_url) }
      format.js { 
        render :update do |page|
          target = "athlete-#{@roster_entry.id}"
          page.replace_html target, :text => ''
          #page.call 'gs.team_sports.show_row'
        end
      }
    end
  end

  def roster
    @team_sport = TeamSport.find(params[:id])

    @roster = RosterEntry.roster(@team_sport.access_group).find(:all, :order => sort_order)#.paginate(:all, :order => sort_order, :page => params[:page])

    if params[:edit]
      edit_me = params[:edit].to_i
      @roster_entry = RosterEntry.find(edit_me)
      if @roster_entry && current_user.can?(Permission::COACH, @roster_entry.team_sport)
        @editing = edit_me
      end
    end

    if @roster_entry.nil?
      @roster_entry = RosterEntry.new()
      @roster_entry.access_group = @team_sport.access_group
    end

    render :layout => false
  end

  def match
    @roster_entry = RosterEntry.find(params[:id])
    @matches = @roster_entry.match_users()
    render :partial=>'match'
  end

  def update_entry

  end


end