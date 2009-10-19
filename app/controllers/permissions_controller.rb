class PermissionsController < BaseController

  #before_filter :admin_required, :only=>[:new, :create, :update, :remove]


  sortable_attributes 'permissions.id', 'permissions.role', 'permissions.blessed_type', 'permissions.blessed_id', 'permissions.scope_type', 'permissions.scope_id'

  def index
#    if !current_user.admin?
#      @permissions = Permission.for_team(current_user.team).paginate(:all, :order => sort_order, :page=>params[:page])
#    else
      @permissions = Permission.paginate(:all, :order => sort_order, :page=>params[:page])
#    end
  end

  def new
    @permission = Permission.new
  end

  def create
    @permission = Permission.new(params[:permission])

    if @permission.save
      redirect_to permissions_path()
    else
      render :action => "new"
    end
  end

  def edit
    @permission = Permission.find(params[:id])
  end

  def update
    @permission = Permission.find(params[:id])

    status = @permission.update_attributes(params[:permission])

    if status
      redirect_to permissions_path()
    else
      render :action => "edit"
    end

  end


  def show

  end


  def destroy
    @permission = Permission.find(params[:id])
    @permission.destroy

    redirect_to permissions_path()
  end



  private

  def team_staff_or_admin
    ( current_user.admin? || current_user.team_staff? ) ? true : access_denied
  end

  def fix_team_name
    if params[:permission]
      team_name = params[:permission][:team_name]
      if team_name
        team = Team.find(:first, :conditions=>{ :name=>team_name })
        params[:permission][:team_id] = team.id
      end
      params[:permission].delete :team_name #[:team] = nil
      #params[:permission][:team_name] = nil
    end
  end

  def instantiate_team_param
    if params[:permission]
      team_name = params[:permission][:team]
      if team_name
        team = Team.find(:first, :conditions=>{ :name=>team_name })
        params[:permission][:team] = team
      end
      if team.nil?
        params[:permission][:team] = nil
      end
    end
  end

  def serialize_team_param
    if @permission.team_id
      params[:permission] = {} if !params[:permission]
      params[:permission][:team] = @permission.team_name
    end
  end





end
