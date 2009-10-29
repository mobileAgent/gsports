class VideoAssetsController < BaseController
  include Viewable
  include ActiveMessaging::MessageSender
  publishes_to :push_video_files
  
  #before_filter :gamex_clean_form, :only=>[:create, :update]
  
  skip_before_filter :verify_authenticity_token, :only => [:auto_complete_for_video_asset_home_team_name,
                                                           :auto_complete_for_video_asset_visiting_team_name,
                                                           :auto_complete_for_video_asset_team_name,
                                                           :auto_complete_for_video_asset_league_name,
                                                           :auto_complete_for_video_asset_sport ]
  
  before_filter :admin_required, :only => [:admin ]
  
  session :cookie_only => false, :only => [:swfupload]
  protect_from_forgery :except => [:swfupload ]
  verify :method => :post, :only => [ :save_video, :swfupload ]
  after_filter :cache_control, :only => [:create, :update, :destroy]
  after_filter :expire_games_of_the_week, :only => [:destroy]
  before_filter :find_user, :only => [:index, :show, :new, :edit, :save_video ]
  before_filter :find_gamex_user, :only => [:index, :show, :new, :save_video ]
  #before_filter :find_staff_scope, :only => [:new, :save_video]
  before_filter :only => [:new, :save_video] do  |c| c.find_staff_scope(Permission::UPLOAD) end



  uses_tiny_mce(:options => AppConfig.narrow_mce_options.merge({:width => 530}),
                :only => [:show])

  def images
    redirect_to "/players/images/#{params[:id]}.#{params[:format]}" and return
  end

  # GET /video_assets
  # GET /video_assets.xml
  def index

    @user = params[:user_id] ? User.find(params[:user_id]) : current_user
    
    # Only admin, league and team staff have video_assets
    # If user isn't one of those, redirect to video_clips
    if(!current_user.admin? && !current_user.team_staff? && !current_user.league_staff?)
      redirect_to user_video_clips_path(@user) and return
    end

    # Team staff can only manage their own accounts
    if (current_user.team_staff? &&
        ! User.team_staff_ids(current_user.team_id).member?(current_user.id))
      redirect_to_user_video_clips_path(@user) and return
    end
    
    # Leagu staff can only manage their own accounts
   if (current_user.league_staff? &&
       ! User.league_staff_ids(current_user.league_id).member?(current_user.id))
     redirect_to_user_video_clips_path(@user) and return
   end

    cond = Caboose::EZ::Condition.new
    cond.user_id == @user.id
    if params[:tag_name]    
      cond.append ['tags.name = ?', params[:tag_name]]
    end
    #cond.append ['video_status = ?','ready']
    
    @video_assets = VideoAsset.paginate(:conditions => cond.to_sql, :page => params[:page], :order => "created_at DESC", :include => :tags)
    @tags = VideoAsset.tags_count :user_id => @user.id, :limit => 20

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @video_assets }
    end
  end
  
  
  sortable_attributes :id, :dockey, :title, :status, 'teams.name', 'leagues.name', 'users.lastname', :video_status
  
  def admin
    @video_assets = VideoAsset.paginate :all, :order=>sort_order, :include => [ :team, :league, :user ], :page => params[:page]
  end

  # GET /video_assets/1
  # GET /video_assets/1.xml
  def show
    @video_asset = VideoAsset.find(params[:id])
    VideoHistory.viewed(@video_asset,current_user)
    update_view_count(@video_asset)
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @video_asset }
    end
  rescue ActiveRecord::RecordNotFound
    flash[:notice] = 'That video could not be found.'
    redirect_to url_for({ :controller => "search", :action => "my_videos" })
  end

  # GET /video_assets/new
  # GET /video_assets/new.xml
  def new
    if @gamex_user
      @render_gamex_tips = true
      load_opponents()
    end
    
    unless current_user.can_upload?
      flash[:notice] = "You don't have permission to upload videos"
      redirect_to url_for({ :controller => "search", :action => "my_videos" }) and return
    end

    @video_asset = VideoAsset.new

    #if is_gamex?
    #  @video_asset.gamex_league_id = @gamex_user.league_id
    #end
        
    # Set default team name in the home team slot to help them figure it out
    unless (current_user.admin? || current_user.league_staff?)
      @video_asset.home_team_name = current_user.team.name
        @video_asset.home_team_name = current_user.team.name
    end

    respond_to do |format|
      format.html # new.html.haml
      format.xml  { render :xml => @video_asset }
    end
  end


  # GET /video_assets/1/edit
  def edit
    @video_asset = VideoAsset.find(params[:id])

    unless (current_user.can_edit?(@video_asset))
      @video_asset = nil
      flash[:notice] = "You don't have permission edit that video"
      redirect_to url_for({ :controller => "search", :action => "my_videos" }) and return
    end

    if league_id = @video_asset.gamex_league_id
        gamex_users_for_video()
        @render_gamex_menu = true
        load_opponents({:for=>:edit})
    end

    

  rescue ActiveRecord::RecordNotFound
    flash[:notice] = 'That video could not be found.'
    redirect_to url_for({ :controller => "search", :action => "my_videos" })
  end

  # POST /video_assets
  # POST /video_assets.xml
  def create
    
    unless current_user.can_upload?
      flash[:notice] = "You don't have permission to upload video"
      redirect_to url_for({ :controller => "search", :action => "my_videos" }) and return
    end
    
    if ! is_gamex?
      gd = params[:video_asset][:game_date] 
      if (gd && gd.length > 0 && gd.length <= 7) # yyyy-mm
        params[:video_asset][:game_date] += '-01'
        params[:video_asset][:ignore_game_day] = true
      end
    end
    @video_asset = VideoAsset.new(params[:video_asset])
    @video_asset.video_status = 'unknown'
    
    respond_to do |format|
      if @video_asset.save!
        flash[:notice] = 'VideoAsset was successfully created.'
        format.html { redirect_to(@video_asset) }
        format.xml  { render :xml => @video_asset, :status => :created, :location => @video_asset }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @video_asset.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /video_assets/1
  # PUT /video_assets/1.xml
  def update
    @video_asset = VideoAsset.find(params[:id])


    unless (current_user.can_edit?(@video_asset))
      @video_asset = nil
      flash[:notice] = "You don't have permission edit that video"
      redirect_to url_for({ :controller => "search", :action => "my_videos" }) and return
    end

    setup_access @video_asset

    respond_to do |format|
      @video_asset.tag_with(params[:tag_list] || '')
      @video_asset = add_team_and_league_relations(@video_asset,params)

      if ! is_gamex?
        gd = params[:video_asset][:game_date]
        params[:video_asset][:ignore_game_month] = false
        params[:video_asset][:ignore_game_day] = false
        params[:video_asset][:game_date_str] = gd
        if (gd && gd.length > 0 && gd.length == 4) # yyyy
          params[:video_asset][:game_date] += "-01"
          params[:video_asset][:ignore_game_month] = true
        end
        gd = params[:video_asset][:game_date]
        if (gd && gd.length > 0 && gd.length == 7) # yyyy-mm
          params[:video_asset][:game_date] += '-01'
          params[:video_asset][:ignore_game_day] = true
        end
      end

      updated = @video_asset.update_attributes(params[:video_asset])

      fix_gamex_fields() if updated

      if updated and @video_asset.save()
        flash[:notice] = 'VideoAsset was successfully updated.'
        format.html { redirect_to(@video_asset) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @video_asset.errors, :status => :unprocessable_entity }
      end
    end
  rescue ActiveRecord::RecordNotFound
    flash[:notice] = 'That video could not be found.'
    redirect_to url_for({ :controller => "search", :action => "my_videos" })
  end

  # DELETE /video_assets/1
  # DELETE /video_assets/1.xml
  def destroy
    @video_asset = VideoAsset.find(params[:id])
    unless (current_user.can_edit?(@video_asset))
      flash[:notice] = "You don't have permission delete that video"
      redirect_to url_for({ :controller => "search", :action => "my_videos" })  and return
    end
    
    @video_asset.destroy

    respond_to do |format|
      format.html { redirect_to(video_assets_url) }
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
    fpath = VideoAsset.move_upload_to_repository(f,params[:Filename])
    @video = VideoAsset.new :uploaded_file_path => fpath, :title => 'Upload in Progress', :user_id => current_user.id
    @video.save!
    render :text => @video.id
  rescue
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
        @video_asset = VideoAsset.find(:last, :conditions => ["user_id = ? and title = 'Upload in Progress' and dockey is null",current_user.id])
        if @video_asset.nil?
          flash[:notice] = "There was a problem with the video"
          render :action=>:upload and return
        end
        logger.debug "Forcing video save fix for video #{@video_asset.id}"
      else
        @video_asset = VideoAsset.find(params[:hidFileID])
      end
      @video_asset.attributes= params[:video_asset]
    else
      @video_asset = VideoAsset.new params[:video_asset]
      # TODO: check for a fallback non-swf file upload and add it here
    end

    # Set up things that don't come naturally from the form
    @video_asset.video_status = 'saving'
    @video_asset.user_id = current_user.id
    @video_asset = add_team_and_league_relations(@video_asset,params)
    
    fix_gamex_fields()
    
    access_ok = setup_access @video_asset
    
    @video_asset.tag_with(params[:tag_list] || '') 

    if access_ok && @video_asset.save
      #publish(:push_video_files,"#{@video_asset.id}")
      flash[:notice] = "Your video is being procesed. It may be several minutes before it appears in your gallery"
      render :action=>:upload_success

      #VideoHistory.uploaded(@video_asset)
    else
      flash[:notice] = "There was a problem with the video"
      render :action=>:new
    end

  end

  def upload_success
  end




  def download

    @video_asset = VideoAsset.find(params[:id])

    if current_user.has_access?(@video_asset)
      VideoHistory.download(@video_asset, current_user)
      redirect_to @video_asset.download_url()
    else
      render :text => 'access denied'
    end

  end



  auto_complete_for :video_asset, :sport

  def auto_complete_for_video_asset_team_name
    render :inline => auto_complete_team_field(params[:video_asset][:team_name])
  end
  
  def auto_complete_for_video_asset_home_team_name
    render :inline => auto_complete_team_field(params[:video_asset][:home_team_name])
  end
  
  def auto_complete_for_video_asset_visiting_team_name
    render :inline => auto_complete_team_field(params[:video_asset][:visiting_team_name])
  end

  def auto_complete_for_video_asset_league_name
    @leagues = League.find(:all, :conditions => ["LOWER(name) like ?", params[:video_asset][:league_name].downcase + '%' ], :order => "name ASC", :limit => 10 )
    choices = "<%= content_tag(:ul, @leagues.map { |l| content_tag(:li, h(l.name)) }) %>"    
    render :inline => choices
  end

  def share
    video = VideoAsset.find(params[:id])
    video.share!
    redirect_to new_message_path(:shared_access_id => video.shared_access_id) 
  rescue ActiveRecord::RecordNotFound
    flash[:notice] = 'That video could not be found.'
    redirect_to url_for({ :controller => "search", :action => "my_videos" })
  end

  private

  def auto_complete_team_field(team_name_start)
    @teams = Team.find(:all, :conditions => ["LOWER(name) like ?", team_name_start.downcase + '%' ], :order => "name ASC", :limit => 10 )
    "<%= content_tag(:ul, @teams.map { |t| content_tag(:li, h(t.name)) }) %>"    
  end


  def old_add_team_and_league_relations_for_reference(video_asset,params)
    
    # Set up team (should only come from admin form)
    admin_set_team = false
    if(current_user.admin? && !params[:video_asset][:team_name].blank?)
      video_asset.team_name= params[:video_asset][:team_name]
      # Transfer ownership to the admin
      admin = User.team_admin(video_asset.team_id)
      video_asset.user_id = admin[0].id if (admin && admin.any?)
      admin_set_team = true
    else
      #this is now a league video
      video_asset.team= nil
      #video_asset.team= current_user.team
    end
    
    # Set up league (should only come from admin form)
    if(current_user.admin? && !params[:video_asset][:league_name].blank?)
      video_asset.league_name= params[:video_asset][:league_name]
      # Transfer ownership to the admin
      admin = User.league_admin(video_asset.league_id)
      video_asset.user_id = admin[0].id if (admin && admin.any?)
      if (video_asset.team_id? && admin_set_team)
        video_asset.team.league_id= video_asset.league_id
      end
    else
      video_asset.league_id= current_user.league_id
    end
    video_asset
  end
  
  def add_team_and_league_relations(video_asset,params)
    
    # Set up team (should only come from admin form)
    admin_set_team = false
    
    
    if(current_user.admin?)
      # Set up league (should only come from admin form)
      
      if(!params[:video_asset][:league_name].blank?)
        video_asset.league_name= params[:video_asset][:league_name]
        if video_asset.gamex_league_id.nil?
          # Transfer ownership to the admin
          admin = User.league_admin(video_asset.league_id)
          video_asset.user_id = admin[0].id if (admin && admin.any?)
        end
        if (video_asset.team_id? && admin_set_team)
          video_asset.team.league_id= video_asset.league_id
        end
      else
        #video_asset.league = nil
      end
      
      if(!params[:video_asset][:team_name].blank?)
        video_asset.team_name= params[:video_asset][:team_name]
        if video_asset.gamex_league_id.nil?
          # Transfer ownership to the admin
          admin = User.team_admin(video_asset.team_id)
          video_asset.user_id = admin[0].id if (admin && admin.any?)
        end
        admin_set_team = true
      else
        video_asset.team = nil
      end

    elsif @scope

      case @scope
      when Team
          video_asset.team= @scope
          video_asset.league_id= @scope.league_id
      when League
          video_asset.team= nil
          video_asset.league_id= @scope.id
      end
      
    else
      # is not an admin
      video_asset.league_id= current_user.league_id

      if current_user.league_staff?
        #this is now a league video
        video_asset.team= nil
      else
        video_asset.team= current_user.team
      end
  
    end
      
      
    video_asset
  end
  

  protected

  def find_user
    @user = params[:user_id] ? User.find(params[:user_id]) : current_user
  end

  def find_gamex_user
    if is_gamex?
      @gamex_users = GamexUser.for_user(current_user)
      @render_gamex_menu = true
      id_s = params[:gamex_user][:id]
      if id_s.empty?
        @gamex_user = @gamex_users.first
      else
        @gamex_user = GamexUser.find( id_s )
      end
      unless @gamex_user.user_id == current_user.id
        access_denied
      end
    end
  end
  
  def gamex_users_for_video()
    if @video_asset && @video_asset.gamex_league_id
      x_user = current_user
      if current_user.admin?
        x_user = @video_asset.user
        #@gamex_user = GamexUser.for_user(@video_asset.user).first
        #@gamex_users = [@gamex_user]
      end
	    @gamex_users = GamexUser.for_user(x_user)
	    @gamex_user = GamexUser.for_user_and_league(x_user,@video_asset.gamex_league_id).first
    end
  end

  def is_gamex?()
    params[ :gamex_user ] and params[:gamex_user][:id]
  end
  
  def fix_gamex_fields()
    if is_gamex? || @video_asset.gamex_league_id
      
      #video_asset = VideoAsset.new(params[:video_asset])
      
      #params[:video_asset][:title] 
      home_team_name = @video_asset.home_team ? @video_asset.home_team.nickname_or_name : ''
      home_team_score = @video_asset.home_score ? " (#{@video_asset.home_score})" : ""
      visiting_team_name = @video_asset.visiting_team ? @video_asset.visiting_team.nickname_or_name : ''
      visitor_team_score = @video_asset.visitor_score ? " (#{@video_asset.visitor_score})" : ""
      game_date = @video_asset.game_date ? @video_asset.game_date.strftime("%m-%d-%Y") : ""
      @video_asset.title = "#{home_team_name}#{home_team_score} vs. #{visiting_team_name}#{visitor_team_score}, #{game_date}"
      
#      if params[:access_item][:access_group_id].empty?
#        @access_item = AccessItem.new(params[:access_item])
#        @access_item.errors.add :access_group, "An Access Group is required."
#        @video_asset.errors.add :id, "An Access Group is required."
#      end
      
    end
  end
  
  

  def cache_control
    Rails.cache.delete('quickfind_sports')
    Rails.cache.delete('quickfind_seasons')
    VideoAsset.seasons_cache_delete
    Rails.cache.delete('quickfind_schools')
  end
  
  def setup_access video
    result = true
    #logger.debug "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    #logger.debug "MEOW setup_access"
    #logger.debug "MEOW params #{params[:access_item].inspect}"
    @access_item = AccessItem.new params[:access_item]
    if @access_item.access_group_id
      @access_item.item = video
      #logger.debug "access_item #{@access_item.inspect}"
      #try this quietly
      result = @access_item.save
      #logger.debug "MEOW #{result.inspect}"
      
    end
    #logger.debug "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    result
  end

  def load_opponents(options={})

    #@video_asset.visiting_team_id
	#if current_user.admin?
      #@opponents = GamexUser.for_user(@video_asset.user).first.teams
	#else
      @opponents = @gamex_user.teams
	#end

    other_team = Team.new({:name=>'Other'}); other_team.id = -1

    if options[:for] == :edit && !@opponents.collect(&:id).include?(@video_asset.visiting_team_id)
      #it's edit time and our team is not in the list
      @show_opponent_text = true
      @opponents = [ other_team ] + @opponents
    else
      @opponents = @opponents + [ other_team ]
    end


  end




end





