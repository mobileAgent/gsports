class StaffsController < BaseController

  before_filter :admin_for_league_or_team

  before_filter :find_staff_scope


  skip_before_filter :verify_authenticity_token, :only => [:auto_complete_for_user_name]





  # GET /staff
  # GET /staff.xml
  def index
    @staffs = @scope ? @scope.staff() : []  #get_managed_users(@current_user, params)

    respond_to do |format|
      format.html # index.haml
      format.xml  { render :xml => @staffs }
    end
  end

  # GET /staff/1
  # GET /staff/1.xml
  def show
    ids = @scope.staff().collect(&:id) #get_managed_user_ids(@current_user, params) # @current_user.get_managed_user_ids
    
    if (ids.member?(params[:id].to_i) || current_user.admin?)
      @staff = Staff.find(params[:id])
    else
      flash[:error] = "Illegal id specified"
      redirect_to url_for({:action => 'index'}) and return
    end

    respond_to do |format|
      format.html # show.haml
      format.xml  { render :xml => @staff }
    end
  end

  # GET /staff/new
  # GET /staff/new.xml
  def new
    @staff = Staff.new

    respond_to do |format|
      format.html # new.haml
      format.xml  { render :xml => @staff }
    end
  end

  # GET /staff/1/edit
  def edit
    ids = @scope.staff().collect(&:id) #get_managed_user_ids(@current_user, params)
    if (ids.member?(params[:id].to_i) || current_user.admin?)
      @staff = Staff.find(params[:id])
    else
      flash[:error] = "Illegal id specified"
      redirect_to url_for({:action => 'index'}) and return
    end
  end

  def add

    
  end

  # POST /staff
  # POST /staff.xml
  def create
    @staff = Staff.new(params[:staff])
    @staff.login="gs#{Time.now.to_i}#{rand(100)}" # We never use this
    @staff.activated_at=Time.now
    # Todo, something better if current_user.admin?
    @staff.team_id= current_user.team_id
    @staff.league_id= current_user.league_id
    @staff.role_id= current_user.team_admin? ? Role[:team_staff].id : Role[:league_staff].id
        
    respond_to do |format|
      if @staff.save && update_permissions(@staff, params[:permission])
        flash[:notice] = 'Staff account was created'
        format.html { redirect_to url_for({:action => 'index'}, {:scope_select=>params[:scope_select]}) }
        format.xml  { render :xml => @staff, :status => :created, :location => @staff }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @staff.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /staff/1
  # PUT /staff/1.xml
  def update
    ids = @scope.staff().collect(&:id) #get_managed_user_ids(@current_user, params) #@current_user.get_managed_user_ids
    
    if (ids.member?(params[:id].to_i) || current_user.admin?)
      @staff = Staff.find(params[:id])
    else
      flash[:error] = "Illegal id specified"
      redirect_to url_for({:action => 'index'}) and return
    end

    respond_to do |format|
      if @staff.update_attributes(params[:staff]) && update_permissions(@staff, params[:permission])
        flash[:notice] = 'Staff was successfully updated.'
        format.html { redirect_to url_for({:action => 'index'}, {:scope_select=>params[:scope_select]})}
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @staff.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /staff/1
  # DELETE /staff/1.xml
  def destroy
    #ids = @scope.staff().collect(&:id) #get_managed_user_ids(@current_user, params)
    @staff = Staff.find(params[:id])

    #if (ids.member?(params[:id].to_i) || current_user.admin?)
    if @scope.is_staff_account?(@staff) 
      @staff.destroy
    else
      flash[:error] = "Illegal id specified"
      redirect_to url_for({:action => 'index'})  and return
    end

    respond_to do |format|
      format.html { redirect_to(url_for({:action => 'index'})) }
      format.xml  { head :ok }
    end
  end

  auto_complete_for :user, :name

  def auto_complete_for_user_name
    @users = []
    
    partial_name = params[:user][:name].to_s.downcase + '%'

    if !partial_name.empty?
      @users = User.find(:all, :conditions => ["LOWER(firstname) like ? OR LOWER(lastname) like ?", partial_name, partial_name ], :order => "firstname, lastname ASC", :limit => 10 )
    end
    
    #erb = "<%= content_tag(:ul, @users.map { |t| content_tag(:li, h(t.full_name)) }) %>"
    #render :inline => erb
  end

  



  private
  
  def update_permissions(staff, permissions)
    
    Permission.staff_permission_list.each(){ |p,name|

      logger.info "STAFFS setting permission: #{name} (#{p}) to #{permissions[p]}"
      
      if permissions[p] == 'y'
        Permission.grant(staff.user, p, @scope)
      else
        Permission.revoke(staff.user, p, @scope)
      end


    }
    
  end


  def find_staff_scope

    @scopes = current_user.scopes_for(Permission::CREATE_STAFF)

    if select = params[:scope_select]
      p, id = select.split(' ')
      params["#{p}_id"]= id

    end

    if (league_id = params[:league_id]) && (league = League.find(league_id)) && current_user.can_manage_staff?(league)
      @scope = league
    elsif (team_id = params[:team_id]) && (team = Team.find(team_id)) && current_user.can_manage_staff?(team)
      @scope = team
    elsif @scopes.size == 1
      @scope = @scopes[0]
    end

  end

end
