class ChannelsController < BaseController
    
  skip_before_filter :gs_login_required, :only => [:show]
  
  def index
    @team = current_user.team
    if !current_user.team_staff?(@team)
      access_denied
      return
    end
    @channels = Channel.paginate(:all, :conditions => {:team_id => @team.id}, :page=>params[:page])
  end

  def new
    @team = current_user.team
    if !current_user.team_staff?(@team)
      access_denied
      return
    end
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

  def add
    if !current_user.team_staff?(current_user.team)
      access_denied
      return
    end
    
    @channel_video = ChannelVideo.new(params[:channel_video])
    
    if @channel_video.channel_id && @channel_video.save
      redirect_to :action => "edit", :id=>@channel_video.channel_id
    else
      @channels = Channel.find(:all, :conditions => {:team_id => @current_user.team_id})
    end
    
  end

  def remove
    if !current_user.team_staff?(current_user.team)
      access_denied
      return
    end
    
    @channel_video = ChannelVideo.find(params[:id])
    @channel_video.destroy if @channel_video
    
    render :update do |page|
      target = "channel_video_#{@channel_video.id}"
      page.replace_html target, :text => ''      
    end
    
    #respond_to do |format|
      #format.js { render :action => "remove" }
    #end    
  end


  def show
    @channel = Channel.find(params[:id])
    
    respond_to do |format|
      format.html {
        render :layout=>'iframe'
      }
      format.xml {
        render :xml=>channel_flash_xml(@channel) #@channel.to_flash_xml
      }
    end
    
  end
  
  def playerVars
    @channel = Channel.find(1)
    render :xml=>channel_flash_xml(@channel) #@channel.to_flash_xml
  end
  
  
  private
  
  def channel_flash_xml(channel, options = {})
    options[:indent] ||= 2
    xml = options[:builder] ||= Builder::XmlMarkup.new(:indent => options[:indent])
    xml.instruct! unless options[:skip_instruct]
    xml.vars {
      xml.playerW(channel.width || 401)
      xml.playerH(channel.height || 401)
      xml.thumbW(channel.thumb_width || 101)
      xml.thumbH(channel.thumb_height || 101)
      xml.numColumnsOrRows(channel.thumb_count || 2)
      xml.dockeys(channel.dockeys())
      xml.homepageLink("#{APP_URL}/#{team_path(channel.team_id)}") if channel.team_id
      
      xml.position(channel.position)
    }
  end
  
  



end
