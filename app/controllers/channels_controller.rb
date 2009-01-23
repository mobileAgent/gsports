class ChannelsController < BaseController
    
  #TODO: tighter authorization
  
  def index
    @team = current_user.team
    if !current_user.team_staff?(@team)
      access_denied
      return
    end
    @channels = Channel.paginate(:all, :conditions => {:team_id => @team.id}, :page=>params[:page])
  end

  def new
    @channel = Channel.new
    @channel.team_id = current_user.team.id
  end

  def create
    @channel = Channel.new(params[:channel])
    @channel.team_id = current_user.team.id
    
    unless current_user.team_staff?(@channel.team)
      flash[:notice] = "You don't have permission to edit that record"
      access_denied
    end
    
    if @channel.save
      redirect_to channels_path()
    else
      render :action => "new"
    end
  end

  def edit
    @channel = Channel.find(params[:id])
  end
  
  def update
    @channel = Channel.find(params[:id])
    
    unless current_user.team_staff?(@channel.team)
      flash[:notice] = "You don't have permission to edit that record"
      access_denied
      return
    else
      status = @channel.update_attributes(params[:channel])
    end

    if status
      redirect_to channels_path()
    else
      render :action => "edit"
    end
    
  end

  def show
    @channel = Channel.find(params[:id])
    render :layout=>false
  end

end
