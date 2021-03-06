class AccessGroupsController < BaseController
    
  #auto_complete_for :access_group, :team
  #skip_before_filter :verify_authenticity_token, :only => [:auto_complete_for_access_group_team ]
  #before_filter :team_staff_or_admin, :except => [:auto_complete_for_access_group ]

  auto_complete_for :access_group, :team_name
  auto_complete_for :user, :name
  skip_before_filter :verify_authenticity_token, :only => [:auto_complete_for_access_group_team_name, :auto_complete_for_user_name ]
  
  #before_filter :team_staff_or_admin, :except => [:auto_complete_for_access_group_team ]
  before_filter  do  |c| c.find_staff_scope(Permission::MANAGE_GROUPS) end
  
  #before_filter :admin_required, :only=>[:new, :create, :update, :remove]
  
  #before_filter :instantiate_team_param, :only=>[:create, :update]
  #after_filter :serialize_team_param, :only=>[:create, :update]
  #before_filter :fix_team_name, :only=>[:create, :update]
  
  
  sortable_attributes 'access_groups.id', 'access_groups.name', 'access_groups.description', 'access_groups.enabled', 'teams.name'
  
  def index
#    if current_user.admin?
#      @access_groups = AccessGroup.paginate(:all, :order => sort_order, :include => [:team], :page=>params[:page])
#    else
      case @scope
      when Team
        @access_groups = AccessGroup.for_team(@scope).paginate(:all, :order => sort_order, :page=>params[:page])
#      when League
#        @access_groups = AccessGroup.for_league(@scope).paginate(:all, :order => sort_order, :page=>params[:page])
      end
#    end
  end

  def new
    @access_group = AccessGroup.new
    @access_group.enabled = true
  end

  def create
    @access_group = AccessGroup.new(params[:access_group])
    
    if @access_group.save
      redirect_to access_groups_path()
    else
      serialize_team_param
      render :action => "new"
    end
  end

  def edit
    @access_group = AccessGroup.find(params[:id])
      serialize_team_param
  end
  
  def update
    @access_group = AccessGroup.find(params[:id])
    
    status = @access_group.update_attributes(params[:access_group])

    if status
      redirect_to access_groups_path()
    else
      serialize_team_param
      render :action => "edit"
    end
    
  end
  
  def users
    @access_group = AccessGroup.find(params[:id])
  end
  
  def items
    @access_group = AccessGroup.find(params[:id])
  end


  def pop_new_user
    @access_group = AccessGroup.find(params[:access_group_id])

    @access_user = AccessUser.new
    @access_user.access_group_id = @access_group

    render :update do |page|
      target = "dialog"
      page.replace_html target, :partial => 'pop_new_user'
    end
  end

  def add_user
    @access_user = AccessUser.new(params[:access_user])

    if @access_user.access_group_id
      if !@access_user.save
        flash[:error] = 'Member not found.'
      end
      redirect_to :action => "users", :id=>@access_user.access_group_id
    end
    
    @access_groups = AccessGroup.for_team(@scope) if @scope
  end

  def remove_user
    @access_user = AccessUser.find(params[:id])
    @access_user.destroy if @access_user

    render :update do |page|
      target = "access_user_#{@access_user.id}"
      page.replace_html target, :text => ''
    end
  end


  def add_video    
    @access_item = AccessItem.new(params[:access_item])
    
    if @access_item.access_group_id
      if @access_item.save
        redirect_to :action => "items", :id=>@access_item.access_group_id
      end
    end
    
    @access_groups = AccessGroup.for_team(@scope) if @scope
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


  def pop_new_contact
    @access_group = AccessGroup.find(params[:access_group_id])

    @access_contact = AccessContact.new
    @access_contact.access_group_id = @access_group

    render :update do |page|
      target = "dialog"
      page.replace_html target, :partial => 'pop_new_contact'
    end
  end

  def add_contact
    @access_contact = AccessContact.new(params[:access_contact])

    if @access_contact.access_group_id
      if @access_contact.save
        redirect_to :action => "index", :scope_select=>Permission.scope_selector_string(@access_contact.access_group.team)
      end
    end

    @access_contact = AccessGroup.for_team(@scope) if @scope
  end

  def remove_contact
    @access_contact = AccessContact.find(params[:id])
    @access_contact.destroy if @access_contact

    render :update do |page|
      target = "access_contact_#{@access_contact.id}"
      page.replace_html target, :text => ''
    end
  end


  def show
    
  end
  
  
  def auto_complete_for_access_group_team_name
    @teams = []
    if params[:access_group] && params[:access_group][:team_name]
      conditions = ["LOWER(name) like ?", params[:access_group][:team_name].downcase + '%' ]
      @teams = Team.find(:all, :conditions => conditions, :order => "name ASC", :limit => 10)
    end
    choices = "<%= content_tag(:ul, @teams.map { |t| content_tag(:li, h(t.name)) }) %>"    
    render :inline => choices
  end


  def auto_complete_for_user_name
    @users = []

    partial_name = params[:user][:name].to_s.downcase + '%'

    if !partial_name.empty?
      @users = User.find(:all, :conditions => ["LOWER(firstname) like ? OR LOWER(lastname) like ?", partial_name, partial_name ], :order => "firstname, lastname ASC", :limit => 10 )
    end

  end
  
  
  
  private
  
  def team_staff_or_admin
    ( current_user.admin? || current_user.team_staff? ) ? true : access_denied
  end
  
  def fix_team_name
    if params[:access_group]
      team_name = params[:access_group][:team_name]
      if team_name
        team = Team.find(:first, :conditions=>{ :name=>team_name }) 
        params[:access_group][:team_id] = team.id
      end
      params[:access_group].delete :team_name #[:team] = nil
      #params[:access_group][:team_name] = nil
    end
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
    if @access_group.team_id
      params[:access_group] = {} if !params[:access_group]
      params[:access_group][:team] = @access_group.team_name
    end
  end
  
  



end
