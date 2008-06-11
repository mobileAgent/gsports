class VidapiController < BaseController
  include ActiveMessaging::MessageSender
  publishes_to :push_video_files

  before_filter :login_required, :only => [:upload, :save_video]
  before_filter :vidavee_login, :except => :logout
  
  # GET /vidapi/logout
  # Cancel our token with the back end
  def logout
    if (session[:vidavee])
      @vidavee = Vidavee.find(:first)
      @vidavee.logout(session[:vidavee])
      session[:vidavee] = nil
      session[:vidavee_expires] = Time.now
    end
  end
  
  # GET /vidapi/upload the upload form
  def upload
    @video_asset = VideoAsset.new unless @video_asset
  end

  # POST /vidapi/save_video
  def save_video
    @video_asset = VideoAsset.new params[:video_asset]
    @video_asset.video_status = 'saving'
    @video_asset.user_id = current_user.id
    ### This is temporary until the user has a team and league linked
    @video_asset.team_id = Team.find(:first).id
    @video_asset.league_id = League.find(:first).id
    ### End temp
    if @video_asset.save!
      publish(:push_video_files,"#{@video_asset.id}")
              
      flash[:notice] = "Your video is being procesed. It may be several minutes before it appears in your gallery"
      render :action=>:upload_success
    else
      flash[:notice] = "There was a problem with the video"
      render :action=>:upload
    end
  end

  def upload_success
  end
  
end
