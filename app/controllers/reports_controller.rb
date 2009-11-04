class ReportsController < BaseController


  #auto_complete_for :access_group, :team_name
  #skip_before_filter :verify_authenticity_token, :only => [:auto_complete_for_access_group_team_name ]

  #before_filter :team_staff_or_admin, :except => [:auto_complete_for_access_group_team ]
  before_filter  do  |c| c.find_staff_scope(Permission::REPORT) end


  sortable_attributes 'reports.id', 'reports.name'

  def index
    
    if @scope
      @reports = Report.for_owner(@scope).paginate(:all, :order => sort_order, :page=>params[:page])
    end

  end

  def new
    @report = Report.new

  end

  def pop_new
    @report = Report.new

    render :update do |page|
      page.replace_html 'dialog', :partial => 'pop_new'
    end

  end

  def create
    @report = Report.new(params[:report])

    @report.owner = @scope
    @report.author = current_user

    if @report.save
      redirect_to edit_reports_path(@report)
    else
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

  def add_user
    @access_user = AccessUser.new(params[:access_user])

    if @access_user.access_group_id
      if @access_user.save
        redirect_to :action => "users", :id=>@access_user.access_group_id
      end
    end

    @access_groups = AccessGroup.for_team(@scope) if @scope
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


  def auto_complete_for_access_group_team_name
    @teams = []
    if params[:access_group] && params[:access_group][:team_name]
      conditions = ["LOWER(name) like ?", params[:access_group][:team_name].downcase + '%' ]
      @teams = Team.find(:all, :conditions => conditions, :order => "name ASC", :limit => 10)
    end
    choices = "<%= content_tag(:ul, @teams.map { |t| content_tag(:li, h(t.name)) }) %>"
    render :inline => choices
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
