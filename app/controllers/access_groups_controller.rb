class AccessGroupsController < BaseController
    
  before_filter :team_staff_or_admin
  before_filter :admin_required, :except=>[:index, :users, :items]
  
  sortable_attributes 'access_groups.id', 'access_groups.name', 'access_groups.description', 'access_groups.enabled', 'teams.name'
  
  def index
    conditions = nil
    conditions = {:team_id=>current_user.team_id, :enabled=>true} if !current_user.admin?
    @access_groups = AccessGroup.paginate(:all, :order => sort_order, :conditions => conditions, :include => [:team], :page=>params[:page])    
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

  def add
    @channel_video = AccessItem.new(params[:channel_video])
    
    if @channel_video.channel_id
      # publish to channel      
      if @channel_video.save
        @channel_video.video.share!
        redirect_to :action => "edit", :id=>@channel_video.channel_id
      end
    end
    
    #else select channel on which to publish video
    @channels = AccessGroup.find(:all, :conditions => {:team_id => @current_user.team_id})
        
  end

  def remove
    @channel_video = AccessItem.find(params[:id])
    @channel_video.destroy if @channel_video
    
    render :update do |page|
      target = "channel_video_#{@channel_video.id}"
      page.replace_html target, :text => ''      
    end  
  end


  def show
    @channel = AccessGroup.find(params[:id])
    
    respond_to do |format|
      format.html {
        render :layout=>'iframe'
      }
      format.xml {
        render :xml=>channel_flash_xml(@channel) #@channel.to_flash_xml
      }
    end
    
  end
  
  private
  
  def team_staff_or_admin
    ( current_user.admin? || current_user.team_staff? ) ? true : access_denied
  end
  
  



end
