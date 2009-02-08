class ChannelsController < BaseController
    
  skip_before_filter :gs_login_required, :only => [:show]
  before_filter :publishing_allowed, :except => [:show]
  
  def index
    @team = current_user.team
    @channels = Channel.paginate(:all, :conditions => {:team_id => @team.id}, :page=>params[:page])
  end

  def new
    @team = current_user.team
    @channel = Channel.new
    @channel.team_id = current_user.team.id
  end

  def create
    @channel = Channel.new(params[:channel])
    @channel.team_id = current_user.team.id
    
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
    
    status = @channel.update_attributes(params[:channel])

    if status
      redirect_to channels_path()
    else
      render :action => "edit"
    end
    
  end

  def add
    @channel_video = ChannelVideo.new(params[:channel_video])
    
    if @channel_video.channel_id
      # publish to channel      
      if @channel_video.save
        @channel_video.video.share!
        redirect_to :action => "edit", :id=>@channel_video.channel_id
      end
    end
    
    #else select channel on which to publish video
    @channels = Channel.find(:all, :conditions => {:team_id => @current_user.team_id})
        
  end

  def remove
    @channel_video = ChannelVideo.find(params[:id])
    @channel_video.destroy if @channel_video
    
    render :update do |page|
      target = "channel_video_#{@channel_video.id}"
      page.replace_html target, :text => ''      
    end  
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
      xml.frameW(channel.frame_width || 201)
      xml.frameH(channel.frame_height || 201)
      xml.playerW(channel.width || 401)
      xml.playerH(channel.height || 401)
      xml.thumbW(channel.thumb_width || 101)
      xml.thumbH(channel.thumb_height || 101)
      xml.numColumnsOrRows(channel.thumb_count || 2)
      xml.numPerColumnOrRow(channel.thumb_span || 2)
      xml.dockeys(channel.dockeys())
      #xml.homepageLink("#{APP_URL}/#{team_path(channel.team_id)}") if channel.team_id
      xml.homepageLink("#{APP_URL}/teams/show_public/#{channel.team_id}") if channel.team_id
      xml.validationUrl(channel.allow_url)
      
      xml.position(channel.position)
    }
  end
  
  def publishing_allowed
    current_user.can_publish? ? true : access_denied
  end



end
