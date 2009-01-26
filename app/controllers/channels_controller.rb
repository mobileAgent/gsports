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

  def add
    @channel_video = ChannelVideo.new(params[:channel_video])
    
    if @channel_video.channel_id && @channel_video.save
      redirect_to :action => "edit", :id=>@channel_video.channel_id
    else
      @channels = Channel.find(:all, :conditions => {:team_id => @current_user.team_id})
    end
    
  end

  def remove
    @channel_video = ChannelVideo.find(params[:id])
    @channel_video.destroy if @channel_video
    
    respond_to do |format|
      format.js { render :action => "remove" }
    end    
  end


  def show
    @channel = Channel.find(params[:id])
    
    respond_to do |format|
      format.html {
        render :layout=>'iframe'
      }
      format.xml {
        render :xml=>channel_flash_xml() #@channel.to_flash_xml
      }
    end
    
  end
  
  
  
  private
  
  def channel_flash_xml(options = {})
    options[:indent] ||= 2
    xml = options[:builder] ||= Builder::XmlMarkup.new(:indent => options[:indent])
    xml.instruct! unless options[:skip_instruct]
    xml.vars {
      xml.playerW(@channel.width)
      xml.playerH(@channel.height)
      xml.thumbW(@channel.thumb_width)
      xml.thumbH(@channel.thumb_width)
      xml.position(@channel.layout)
      xml.numColumnsOrRows(@channel.thumb_count)
      xml.dockeys(@channel.dockeys())
      xml.homepageLink("#{APP_URL}/#{team_path(@channel.team_id)}") if @channel.team_id
    }
  end



end
