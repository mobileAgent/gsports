class AccessGroupsController < BaseController
    
  auto_complete_for :access_group, :team
  skip_before_filter :verify_authenticity_token, :only => [:auto_complete_for_access_group_team ]
  before_filter :team_staff_or_admin, :except => [:auto_complete_for_access_group_team ]
  before_filter :admin_required, :only=>[:new, :create, :update, :remove]
  
  before_filter :instantiate_team_param, :only=>[:create, :update]
  after_filter :serialize_team_param, :only=>[:create, :update]
  
  
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
    @access_user = AccessUser.new(params[:access_user])

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
      target = "access_item_#{@access_item.id}"
      page.replace_html target, :text => ''      
    end  
  end

  def remove_user
    @access_user = AccessUser.find(params[:id])
    @access_user.destroy if @access_user

    render :update do |page|
      target = "access_user_#{@access_user.id}"
      page.replace_html target, :text => ''      
    end  
  end


  def show
    
  end
  
  
  def auto_complete_for_access_group_team
    @teams = []
    if params[:access_group] && params[:access_group][:team]
      conditions = ["LOWER(name) like ?", params[:access_group][:team].downcase + '%' ]
      @teams = Team.find(:all, :conditions => conditions, :order => "name ASC", :limit => 10)
    end
    choices = "<%= content_tag(:ul, @teams.map { |t| content_tag(:li, h(t.name)) }) %>"    
    render :inline => choices
  end
  
  
  
  
  
  private
  
  def team_staff_or_admin
    ( current_user.admin? || current_user.team_staff? ) ? true : access_denied
  end
  
  
  def instantiate_team_param
    if params[:access_group]
      team_name = params[:access_group][:team]
      if team_name
        team = Team.find(:first, :conditions=>{ :name=>team_name }) 
        params[:access_group][:team] = team
      end
      if team.nil?
        params[:access_group][:team] = nil
      end
    end
  end
  
  def serialize_team_param
    team = params[:access_group][:team]
    params[:access_group][:team] = team ? team.name : ''
  end
  
  



end
