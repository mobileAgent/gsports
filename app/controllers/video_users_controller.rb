class VideoUsersController < BaseController
  
  include Viewable
  include ActiveMessaging::MessageSender
  publishes_to :push_user_video_files
  
  before_filter :admin_required, :only => [:admin ]
  
  session :cookie_only => false, :only => [:swfupload]
  protect_from_forgery :except => [:swfupload ]
  verify :method => :post, :only => [ :save_video, :swfupload ]
  #after_filter :cache_control, :only => [:create, :update, :destroy]
  #before_filter :find_user, :only => [:index, :show, :new, :edit ]
  #uses_tiny_mce(:options => AppConfig.narrow_mce_options.merge({:width => 530}), :only => [:show])
  
  def images
    redirect_to "/players/images/#{params[:id]}.#{params[:format]}" and return
  end


  def index

    @user = params[:user_id] ? User.find(params[:user_id]) : current_user
    
    cond = Caboose::EZ::Condition.new
    cond.user_id == @user.id
    if params[:tag_name]    
      cond.append ['tags.name = ?', params[:tag_name]]
    end
    #cond.append ['video_status = ?','ready']
    
    @video_users = VideoUser.paginate(:conditions => cond.to_sql, :page => params[:page], :order => "created_at DESC", :include => :tags)
    @tags = VideoUser.tags_count :user_id => @user.id, :limit => 20

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @video_users }
    end
  end
  
  
  sortable_attributes :id, :dockey, :title, 'users.lastname', :video_status
  
  def admin
    @video_users = VideoUser.paginate :all, :order=>sort_order, :include => [ :user ], :page => params[:page]
  end

  def show
    @video_user = VideoUser.find(params[:id])
    update_view_count(@video_user)
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @video_user }
    end
  rescue ActiveRecord::RecordNotFound
    flash[:notice] = 'That video could not be found.'
    redirect_to url_for({ :controller => "search", :action => "my_videos" })
  end


  def new
    @video_user = VideoUser.new
    
    @user = params[:user_id] ? User.find(params[:user_id]) : current_user

    respond_to do |format|
      format.html # new.html.haml
      format.xml  { render :xml => @video_user }
    end
  end


  def edit
    @user = params[:user_id] ? User.find(params[:user_id]) : current_user
  
    @video_user = VideoUser.find(params[:id])
    unless ( @video_user.user_id == current_user || current_user.can_edit?(@video_user) )
      @video_user = nil
      flash[:notice] = "You don't have permission edit that video"
      redirect_to url_for({ :controller => "search", :action => "my_videos" }) and return
    end
  rescue ActiveRecord::RecordNotFound
    flash[:notice] = 'That video could not be found.'
    redirect_to url_for({ :controller => "search", :action => "my_videos" })
  end


  def create
        
    vd = params[:video_user][:video_date] 
    if (vd && vd.length > 0 && vd.length <= 7) # yyyy-mm
      params[:video_user][:video_date] += '-01'
    end
    @video_uses = VideoUser.new(params[:video_user])
    @video_user.video_status = 'unknown'
      
    respond_to do |format|
      if @video_user.save!
        flash[:notice] = 'VideoAsset was successfully created.'
        format.html { redirect_to(@video_user) }
        format.xml  { render :xml => @video_user, :status => :created, :location => @video_user }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @video_user.errors, :status => :unprocessable_entity }
      end
    end
  end


  def update
    @video_user = VideoUser.find(params[:id])
    unless (current_user.can_edit?(@video_user))
      @video_user = nil
      flash[:notice] = "You don't have permission edit that video"
      redirect_to url_for({ :controller => "search", :action => "my_videos" }) and return
    end

    respond_to do |format|
      @video_user.tag_with(params[:tag_list] || '') 
      #@video_user = add_team_and_league_relations(@video_asset,params)
      
      gd = params[:video_user][:game_date]
      params[:video_user][:ignore_game_month] = false
      params[:video_user][:ignore_game_day] = false
      params[:video_user][:game_date_str] = gd
      if (gd && gd.length > 0 && gd.length == 4) # yyyy
        params[:video_user][:game_date] += "-01"
        params[:video_user][:ignore_game_month] = true
      end
      gd = params[:video_user][:game_date]
      if (gd && gd.length > 0 && gd.length == 7) # yyyy-mm
        params[:video_user][:game_date] += '-01'
        params[:video_user][:ignore_game_day] = true
      end
        
      if @video_user.update_attributes(params[:video_user])
        flash[:notice] = 'VideoUser was successfully updated.'
        format.html { redirect_to(@video_user) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @video_user.errors, :status => :unprocessable_entity }
      end
    end
  rescue ActiveRecord::RecordNotFound
    flash[:notice] = 'That video could not be found.'
    redirect_to url_for({ :controller => "search", :action => "my_videos" })
  end

  # DELETE /video_assets/1
  # DELETE /video_assets/1.xml
  def destroy
    @video_user = VideoUser.find(params[:id])
    unless (current_user.can_edit?(@video_user))
      flash[:notice] = "You don't have permission delete that video"
      redirect_to url_for({ :controller => "search", :action => "my_videos" })  and return
    end
    
    @video_user.destroy

    respond_to do |format|
      format.html { redirect_to(video_users_url) }
      format.xml  { head :ok }
      format.js
    end
  rescue ActiveRecord::RecordNotFound
    flash[:notice] = 'That video could not be found.'
    redirect_to url_for({ :controller => "search", :action => "my_videos" })
  end

  # POST /video_assets/swfupload comes from the video_uploader.js 
  def swfupload
    f = params[:Filedata] # the tmp file
    fpath = VideoUser.move_upload_to_repository(f,params[:Filename])
    @video = VideoUser.new :uploaded_file_path => fpath, :title => 'Upload in Progress', :user_id => current_user.id
    @video.save!
    render :text => @video.id
  rescue => e
    logger.warn e.inspect
    render :text => "Error saving file"
  end
  
  # POST /vidapi/save_video (the rest of the form after the swfupload)
  def save_video
    if params[:hidFileID]
      # Here we are hacking around a problem with ultra large
      # uploads where swfupload flash object is apparently timing out
      # and closing the connection, never getting the response from
      # the swfupload action above. Since it doesn't have the @video.id
      # it's going to send us a -1 when the form submit is forces
      # and we will just look up the last pending upload for the user.
      if (params[:hidFileID] == "-1")
        @video_user = VideoUser.find(:last, :conditions => ["user_id = ? and title = 'Upload in Progress' and dockey is null",current_user.id])
        if @video_user.nil?
          flash[:notice] = "There was a problem with the video"
          render :action=>:upload and return
        end
        logger.debug "Forcing video save fix for video #{@video_user.id}"
      else
        @video_user = VideoUser.find(params[:hidFileID])
      end
      @video_user.attributes= params[:video_user]
    else
      @video_user = VideoUser.new params[:video_user]
      # TODO: check for a fallback non-swf file upload and add it here
    end

    # Set up things that don't come naturally from the form
    @video_user.video_status = 'saving'
    @video_user.user_id = current_user.id
    
    @video_user.tag_with(params[:tag_list] || '') 

    if @video_user.save
      #publish(:push_user_video_files,"#{@video_user.id}")
      flash[:notice] = "Your video is being procesed. It may be several minutes before it appears in your gallery"
      render :action=>:upload_success
    else
      flash[:notice] = "There was a problem with the video"
      @user = params[:user_id] ? User.find(params[:user_id]) : current_user
      render :action=>:new
    end
  end

  def upload_success
  end

  def share
    video = VideoUser.find(params[:id])
    video.share!
    redirect_to new_message_path(:shared_access_id => video.shared_access_id) 
  rescue ActiveRecord::RecordNotFound
    flash[:notice] = 'That video could not be found.'
    redirect_to url_for({ :controller => "search", :action => "my_videos" })
  end

  private
  

  protected

  def find_user
    @user = params[:user_id] ? User.find(params[:user_id]) : current_user
  end


end
