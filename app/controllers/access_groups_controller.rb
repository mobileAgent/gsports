class AccessGroupsController < BaseController
    
  before_filter :team_staff_or_admin
  before_filter :admin_required, :only=>[:new, :create, :update, :remove]
  
  sortable_attributes 'access_groups.id', 'access_groups.name', 'access_groups.description', 'access_groups.enabled', 'teams.name'
  
  def index
    if !current_user.admin?
      @access_groups = AccessGroup.for_team(current_user.team).paginate(:all, :order => sort_order, :page=>params[:page])  
    else
      @access_groups = AccessGroup.paginate(:all, :order => sort_order, :include => [:team], :page=>params[:page])    
    end
  end

  def new
    @access_group = AccessGroup.new
  end

  def create
    @access_group = AccessGroup.new(params[:access_group])
    
    if @access_group.save
      redirect_to access_groups_path()
    else
      render :action => "new"
    end
  end

  def edit
    @access_group = AccessGroup.find(params[:id])
  end
  
  def update
    @access_group = AccessGroup.find(params[:id])
    
    status = @access_group.update_attributes(params[:access_group])

    if status
      redirect_to access_groups_path()
    else
      render :action => "edit"
    end
    
  end

  def users
    @access_group = AccessGroup.find(params[:id])
  end
  
  def items
    @access_group = AccessGroup.find(params[:id])
  end

  def add_user
    @access_user = AccessUser.new(params[:access_item])

    if @access_user.access_group_id
      if @access_user.save
        redirect_to :action => "users", :id=>@access_user.access_group_id
      end
    end
    
    @access_groups = AccessGroup.for_team(current_user.team)
  end

  def add_video    
    @access_item = AccessItem.new(params[:access_item])
    
    if @access_item.access_group_id
      if @access_item.save
        redirect_to :action => "items", :id=>@access_item.access_group_id
      end
    end
    
    @access_groups = AccessGroup.for_team(current_user.team)
  end

  def remove_video
    @access_item = AccessItem.find(params[:id])
    @access_item.destroy if @access_item
    
    #TODO access check?
    
    render :update do |page|
      target = "channel_video_#{@channel_video.id}"
      page.replace_html target, :text => ''      
    end  
  end


  def show
    
  end
  
  private
  
  def team_staff_or_admin
    ( current_user.admin? || current_user.team_staff? ) ? true : access_denied
  end
  
  



end