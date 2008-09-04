class StaffsController < BaseController

  before_filter :admin_for_league_or_team

  # GET /staff
  # GET /staff.xml
  def index
    @staffs = get_managed_users

    respond_to do |format|
      format.html # index.haml
      format.xml  { render :xml => @staffs }
    end
  end

  # GET /staff/1
  # GET /staff/1.xml
  def show
    ids = get_managed_user_ids
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
    ids = get_managed_user_ids
    if (ids.member?(params[:id].to_i) || current_user.admin?)
      @staff = Staff.find(params[:id])
    else
      flash[:error] = "Illegal id specified"
      redirect_to url_for({:action => 'index'}) and return
    end
  end

  # POST /staff
  # POST /staff.xml
  def create
    @staff = Staff.new(params[:staff])
    @staff.login="gs#{Time.now.to_i}#{rand(100)}" # We never use this
    @staff.enabled=true
    @staff.activated_at=Time.now
    # Todo, something better if current_user.admin?
    @staff.team_id= current_user.team_id
    @staff.league_id= current_user.league_id
    @staff.role_id= current_user.team_admin? ? Role[:team_staff].id : Role[:league_staff].id
    
    respond_to do |format|
      if @staff.save
        flash[:notice] = 'Staff account was created'
        format.html { redirect_to url_for({:action => 'index'}) }
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
    ids = get_managed_user_ids
    if (ids.member?(params[:id].to_i) || current_user.admin?)
      @staff = Staff.find(params[:id])
    else
      flash[:error] = "Illegal id specified"
      redirect_to url_for({:action => 'index'}) and return
    end

    respond_to do |format|
      if @staff.update_attributes(params[:staff])
        flash[:notice] = 'Staff was successfully updated.'
        format.html { redirect_to url_for({:action => 'index'})}
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
    ids = get_managed_user_ids
    if (ids.member?(params[:id].to_i) || current_user.admin?)
      @staff = Staff.find(params[:id])
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

  private

  def get_managed_user_ids
    get_managed_users.collect(&:id)
  end

  def get_managed_users
    if current_user.league_admin? || (current_user.admin? && params[:league_id])
      Staff.league_staff(current_user.league_id)
    elsif current_user.team_admin? || (current_user.admin? && params[:team_id])
      Staff.team_staff(current_user.team_id)
    else
      []
    end
  end

end
