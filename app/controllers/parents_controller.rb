class ParentsController < BaseController

  before_filter :except => [:show] do  |c| c.find_staff_scope(Permission::COACH) end

  skip_before_filter :verify_authenticity_token, :only => [ :post ]

  sortable_attributes 'id', 'firstname', 'lastname', 'email', 'phone'


  def index
  end


  def show
  end


  def new
    @parent = Parent.new
  end


  def post

    @parent = nil

    saved = false
    msg = ''

    begin
      @parent = Parent.find(params[:parent][:id])

      if current_user.can?(Permission::COACH, @parent.roster_entry.team_sport)
        saved = @parent.update_attributes(params[:parent])
      else
        msg = "You don't have permission to edit that record"
      end

    rescue
      #it's new

      @parent = Parent.new(params[:parent])

      if current_user.can?(Permission::COACH, @parent.roster_entry.team_sport)
        saved = @parent.save
      else
        msg = "You don't have permission to edit that record"
      end

    end

    render :update do |page|
      if saved
        flashnow(page,"Parent entry was successfully updated.")
        page.call 'gs.team_sports.sort_row', "/roster_entries/roster/#{@parent.roster_entry.team_sport.id}?order=descending&sort=id"


      else
        #page.replace_html 'staff_summary', :text => 'zoom'
        flashnow(page,"Roster entry could not be updated.")
        flashnow(page,msg,'error')
      end
    end

  end

  def destroy
    @parent = Parent.find(params[:id])

    unless current_user.can?(Permission::COACH, @parent.roster_entry.team_sport)
      flash[:notice] = "You don't have permission to edit that record"
      access_denied and return
    end

    @parent.destroy

    #redirect_to(team_sports_url)

    respond_to do |format|
      format.html { redirect_to(team_sports_url) }
      format.js {
        render :update do |page|
          #target = "parent-#{@parent.id}"
          #page.replace_html target, :text => ''
          page.call 'gs.team_sports.load_current'
        end
      }
    end
  end

end