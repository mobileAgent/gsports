class SearchController < BaseController
  
  skip_before_filter :verify_authenticity_token, :only => [ :quickfind, :quickfind_select_state, :quickfind_select_county, :quickfind_select_school ]
  skip_before_filter :gs_login_required, :only => [:teamfind,:update_teamfind_counties,:update_teamfind_cities,:dd]
  before_filter :vidavee_login
  
  # Video quickfind
  def quickfind
    @user = current_user
    @video_assets = VideoAsset.quickfind(params)
    @is_search_result = true
    protect_private_videos(@video_assets)
    @search_result_size = @video_assets.size
    @title = 'Video Quickfind Results'
    render :action => 'my_videos'
  end

  def quickfind_select_state
    @state = (params[:state] || 0).to_i
    counties = @state > 0 ? Team.counties(@state) : @quickfind_counties
    schools = @state > 0 ? Team.find(:all, :conditions=>{:state_id=>@state}, :order => 'name ASC') : @quickfind_schools

    render :update do |page|
      page.replace_html 'quickfind_counties', :partial => 'quickfind_counties', :object => counties
      page.replace_html 'quickfind_schools',  :partial => 'quickfind_schools',  :object => schools
    end
  end

  def quickfind_select_county
    @state = (params[:state] || 0).to_i
    @county = (params[:county] || "")
    if @state > 0
      cond = ["county_name = ? and state_id = ?",@county,@state]
    else
      cond = ["county_name = ?",@county]
    end
    schools = !@county.empty? ? Team.find(:all, :conditions => cond, :order => 'name ASC') : @quickfind_schools
    
    render :update do |page|
      page.replace_html 'quickfind_schools',  :partial => 'quickfind_schools',  :object => schools
    end
  end

  def quickfind_select_school
    school = (params[:school] || 0).to_i
    sports = school > 0 ? VideoAsset.sports(school) : @quickfind_sports
    seasons = school > 0 ? VideoAsset.seasons(school) : @quickfind_seasons

    render :update do |page|
      page.replace_html 'quickfind_sports',   :partial => 'quickfind_sports',   :object => sports
      page.replace_html 'quickfind_seasons',   :partial => 'quickfind_seasons',   :object => seasons
    end
  end


  
  
  # Main site search
  def q
    @category = (params[:search][:category] || "0").to_i
    @is_search_result = true
        
    case @category
    when Search::ALL
      @videos = sphinx_search_videos
      protect_private_videos(@videos)
      @title = 'Search Results'
      @users = sphinx_search_users
      @teams = sphinx_search_teams
      @leagues = sphinx_search_leagues
      @posts = sphinx_search_blogs

      tl_size = @teams.size + @leagues.size
      
      # The search layout looks dumb if two columns are empty
      if @users.size + @posts.size + tl_size == 0
        render :action => 'video_listing'
      elsif @users.size + @videos.size + tl_size == 0
        render :action => 'post_listing'
      elsif @posts.size + @videos.size + tl_size == 0
        render :action => 'user_listing'
      else
        render :action => 'search'
      end
      
    when Search::VIDEO
      logger.debug "Routing search to video category"
      @videos = sphinx_search_videos
      protect_private_videos(@videos)
      @title = 'Search Results'
      render :action => 'video_listing'
      
    when Search::USERS
      logger.debug "Routing search to user category"
      @users = sphinx_search_users
      render :action => 'user_listing'
      
    when Search::BLOGS
      logger.debug "Routing search to blog category"
      @posts = sphinx_search_blogs
      render :action => 'post_listing'
      
    when Search::TEAMS  
      logger.debug "Routing search to team category"
      @teams = sphinx_search_teams
      render :action => 'team_listing'
      
    when Search::LEAGUES  
      logger.debug "Routing search to league category"
      @leagues = sphinx_search_leagues
      render :action => 'league_listing'
      
    when Search::TEAM_USERS
      logger.debug "Routing search to team user category"
      @users = activerecord_search_team
      render :action => 'user_listing'
      
    when Search::LEAGUE_USERS
      logger.debug "Routing search to league user category"
      @users = activerecord_search_league
      render :action => 'user_listing'
      
    when Search::FRIENDS
      logger.debug "Routing search to friend category"
      @users = sphinx_search_friends
      render :action => 'user_listing'
      
    end
    
  end

  # The public pass-through for the "d" method
  # requiring both a dockey and a shared_access key
  def dd
    dockey = params[:dockey]
    sakey = params[:sakey]
    unless dockey.nil?
      unless sakey.nil?
        shared_access = SharedAccess.find_by_key(sakey)
        if shared_access
          case shared_access.item_type
          when SharedAccess::TYPE_VIDEO
            @video = VideoAsset.first :conditions => { :id => shared_access.item_id.to_i, :dockey => dockey }
          when SharedAccess::TYPE_CLIP
            @video = VideoClip.first :conditions => { :id => shared_access.item_id.to_i, :dockey => dockey }
          when SharedAccess::TYPE_REEL
            @video = VideoReel.first :conditions => { :id => shared_access.item_id.to_i, :dockey => dockey }
          end
        end
      end

      if @video
        # get full metadata xml for shared_access videos 
        xstr = video_metadata_xml @video, true
      else
        @video = VideoAsset.find_by_dockey(dockey) || VideoClip.find_by_dockey(dockey) || VideoReel.find_by_dockey(dockey)
        if @video
          # for public-access, get scaled-down metadata xml
          xstr = video_metadata_xml @video, false
        end
      end

      if xstr
        render :xml => xstr and return
      end
    end
    render :inline => '<video-asset>not found</video-asset>' and return   
  end

  # The flash player uses this to get metadata for
  # any video object by dockey
  def d
    dockey = params[:dockey]
    @video = VideoAsset.find_by_dockey(dockey) || VideoClip.find_by_dockey(dockey) || VideoReel.find_by_dockey(dockey)
    if @video
      xstr = video_metadata_xml @video
      render :xml => xstr and return if xstr
    end
    render :inline => '<video-asset>not found</video-asset>' and return   
  end

  
  def my_videos
    @user = params[:user_id] ? User.find(params[:user_id]) : current_user
    
    @video_assets = VideoAsset.for_user(@user).all(:limit => 10, :order => 'updated_at DESC')
    @video_clips = VideoClip.for_user(@user).all(:limit => 10, :order => 'updated_at DESC')
    @video_reels = VideoReel.for_user(@user).all(:limit => 10, :order => 'updated_at DESC')
    protect_private_videos(@video_assets)
    protect_private_videos(@video_clips)
    protect_private_videos(@video_reels)
  end
  
  # This is not as straight-forward as video assets where the user_id is the
  # current user. That has it's place, but we need more.
  def my_video_assets
    @user = params[:user_id] ? User.find(params[:user_id]) : current_user
    @video_assets = VideoAsset.for_user(@user).paginate(:page => params[:page], :order => 'updated_at DESC')
    protect_private_videos(@video_assets)
    render :action => "my_videos"
  end
  
  def my_video_clips
    @user = params[:user_id] ? User.find(params[:user_id]) : current_user
    @video_clips = VideoClip.for_user(@user).paginate(:page => params[:page], :order => 'updated_at DESC')
    protect_private_videos(@video_clips)
    render :action => "my_videos"
  end
  
  def my_video_reels
    @user = params[:user_id] ? User.find(params[:user_id]) : current_user
    @video_reels = VideoReel.for_user(@user).paginate(:page => params[:page], :order => 'updated_at DESC')
    protect_private_videos(@video_reels)
    render :action => "my_videos"
  end
  
  def team_video_assets
    @user = current_user
    @team = Team.find(params[:team_id])
    @title = @team.name
    @video_assets = VideoAsset.for_team(@team).paginate(:page => params[:page], :order => 'updated_at DESC')
    protect_private_videos(@video_assets)
    render :action => "my_videos"
  end

  def league_video_assets
    @user = current_user
    @league = League.find(params[:league_id])
    @title = @league.name
    @video_assets = VideoAsset.for_league(@league).paginate(:page => params[:page], :order => 'updated_at DESC')
    render :action => "my_videos"
  end

  
  def teamfind
    cond = Caboose::EZ::Condition.new
    cond.append ['state_id = ?',params[:state]]
    cond.append ['county_name = ?', params[:county]]
    cond.append ['city = ?', params[:city]]
    #cond.append ['name = ?', params[:name]]
    
    @teams = Team.paginate(:conditions => cond.to_sql, :page => params[:page], :order => 'teams.name ASC')
    logger.debug "Found #{@teams.total_entries} entries on #{@teams.total_pages} pages"
  end
  
  def update_teamfind_counties
    @state = (params[:state] || 0).to_i
    teamfind_counties = @state > 0 ? Team.counties(@state) : @quickfind_counties
    quickfind_cities = @state > 0 ? Team.find(:all,:select => "DISTINCT city",:conditions => "state_id = '#{@state}' AND city IS NOT NULL",:order => 'city ASC') : @quickfind_cities
      
    render :update do |page|
      page.replace_html 'teamfind_counties', :partial => 'teamfind_counties', :object => teamfind_counties
      page.replace_html 'teamfind_cities',   :partial => 'teamfind_cities',   :object => quickfind_cities
    end
  end
  
  def update_teamfind_cities
    @state = (params[:state] || 0).to_i
    @county = (params[:county] || "")
    
    teamfind_cities = !@county.empty?  ? Team.cities(@county,@state) : @quickfind_cities

    render :update do |page|
      page.replace_html 'teamfind_cities',   :partial => 'teamfind_cities',   :object => teamfind_cities
    end
  end
  
  protected

  def sphinx_search_users
    logger.debug "Running user search for #{params[:search][:keyword]}"
    @users = User.search(params[:search][:keyword],
                         :conditions => { :profile_public => 1, :enabled => 1 },
                         :per_page => 30,
                         :page => (params[:page] || 1),
                         :order => :full_name)
  end

  def sphinx_search_leagues
    logger.debug "Running league search for #{params[:search][:keyword]}"
    League.search(params[:search][:keyword],
      :per_page => 6,
      :page => (params[:page] || 1),
      :order => :name)
  end

  def sphinx_search_teams
    logger.debug "Running team search for #{params[:search][:keyword]}"
    Team.search(params[:search][:keyword],
      :per_page => 6,
      :page => (params[:page] || 1),
      :order => :nickname)
  end
  
  def sphinx_search_blogs
    logger.debug "Running blog search for #{params[:search][:keyword]}"
    @posts = Post.search(params[:search][:keyword],
                         :conditions => { :published_as => 'live' },
                         :page => (params[:page] || 1),
                         :per_page => 30,
                         :order => :published_at, :sort_mode => :desc)
  end

  def sphinx_search_videos
    @user = params[:user_id] ? User.find(params[:user_id]) : current_user
    @search_keyword = '*'
    if params[:search] && params[:search][:keyword]
      @search_keyword = params[:search][:keyword]
    end
    
    @videos = ThinkingSphinx::Search.search(params[:search][:keyword],
                                            :per_page => 30,
                                            :page => (params[:page] || 1),
                                            :classes => [VideoAsset, VideoReel, VideoClip],
                                            # :conditions => { :public_video => 1 },
                                            :order => 'updated_at DESC')
  end
  

  def activerecord_search_team
    @team = Team.find(params[:team_id])
    User.paginate(:all, 
                  :conditions=>{:team_id => @team.id, :enabled => true },
                  :per_page => 30,
                  :page => (params[:page] || 1),
                  :order => 'lastname, firstname'
                  )
  end
  
  def activerecord_search_league
    @league = League.find(params[:league_id])
    User.paginate(:all, 
                  :conditions=>{:league_id => @league.id, :enabled => true },
                  :per_page => 30,
                  :page => (params[:page] || 1),
                  :order => 'lastname, firstname'
                  )
  end

  
  def sphinx_search_friends
    User.search(params[:search][:keyword],
                :conditions => { :profile_public => 1, :friend_id => params[:friend_id] },
                :per_page => 30,
                :page => (params[:page] || 1),
                :order => :full_name)
  end

  # Remove private videos from search results
  def protect_private_videos(videos)
    logger.debug "In protect_private_videos"
    if (videos && videos.any? && current_user && (! current_user.admin? ))
      logger.debug "Before videos #{videos.size}"
      videos.reject!{|v| v.public_video == false && v.user_id != current_user.id}
      logger.debug "After videos #{videos.size}"
    end
  end

  def video_metadata_xml(video, deep=true)
    xml_options = {:dasherize => false, :skip_types => true}

    case video
    when VideoAsset
      logger.debug "Video Asset to xml..."
      if deep
        xml_options[:except] = [:game_date, :game_date_str, :created_at, :updated_at, :uploaded_file_path, 
                                :league_id, :team_id, :user_id, :delta, :video_type, :visiting_team_id, :home_team_id, :ignore_game_day, :ignore_game_month, 
                                :gsan, :internal_notes, :announcer, :filmed_by, 
                                :shared_access_id]
      else
        xml_options[:only] = [:description, :title, :video_length, :view_count, :id]
      end
      xstr = video.to_xml(xml_options) do |xml|
        xml.type 'VideoAsset'
        xml.created_at video.created_at.to_s(:readable)
        xml.updated_at video.updated_at.to_s(:readable)
        xml.favorite_count video.favorites.size
        xml.thumbnail_url @vidavee.file_thumbnail_medium(video.dockey)

        if deep
          xml.game_date video.human_game_date_string
          xml.league_name video.league_name if video.league_id
          xml.team_name video.team.title_name if video.team_id
          if video.league_video?
            xml.owner_name video.league_name
            xml.owner_name_url league_path(video.league)
          elsif (video.team_id?)
            xml.owner_name video.team.title_name
            xml.owner_name_url team_path(video.team)
          else
            xml.owner_name video.user.full_name
            xml.owner_name_url user_path(video.user_id)
          end
          if video.user_id
            xml.user_name video.user.full_name
          else
            xml.user_name 'system'
          end
          if video.visiting_team_id
            xml.visiting_team_name video.visiting_team.title_name 
            xml.visiting_team_url team_path(video.visiting_team)
          end
          if video.home_team_id
            xml.home_team_name video.home_team.title_name
            xml.home_team_url team_path(video.home_team)
          end
          xml.tags video.tags.collect(&:name).join(', ')
        end
      end
    when VideoClip
      logger.debug "Video Clip to xml..."
      if deep
        xml_options[:except] = [:created_at, :updated_at, :delta, :video_asset_id, :shared_access_id]
      else
        xml_options[:only] = [:description, :title, :video_length, :view_count, :user_id, :id]
      end
      xstr = video.to_xml(xml_options) do |xml|
        xml.type 'VideoClip'
        xml.created_at video.created_at.to_s(:readable)
        xml.updated_at video.updated_at.to_s(:readable)
        xml.favorite_count video.favorites.size
        xml.thumbnail_url @vidavee.file_thumbnail_medium(video.dockey)
        if deep
          xml.parent_dockey video.video_asset.dockey
          xml.parent_name video.video_asset.title
          xml.parent_url video_asset_path(video.video_asset_id)
          xml.tags video.tags.collect(&:name).join(', ')
          xml.rating video.rating
          xml.rate_url "/ratings/rate/#{video.id}?type=VideoClip&rating="
          if video.user_id
            xml.owner_name video.user.full_name
            xml.owner_name_url user_path(video.user)
            unless video.user.league_staff?
              xml.team_name video.user.team.title_name 
              xml.team_url team_path(video.user.team)
            end
            if video.user.league_staff?
              xml.league_name video.user.league_name
              xml.league_url league_path(video.user.league)
            end
          else
            xml.user_name 'system'
          end
        end
      end
    when VideoReel
      logger.debug "Video Reel to xml..."
      if deep
        xml_options[:except] = [:created_at, :updated_at, :delta, :shared_access_id]
      else
        xml_options[:only] = [:description, :title, :video_length, :view_count, :user_id, :id]
      end
      xstr = video.to_xml(xml_options) do |xml|
        xml.type 'VideoReel'
        xml.created_at video.created_at.to_s(:readable)
        xml.updated_at video.updated_at.to_s(:readable)
        xml.favorite_count video.favorites.size
        xml.thumbnail_url @vidavee.file_thumbnail_medium(video.thumbnail_dockey)
        if deep
          if video.user_id
            xml.owner_name video.user.full_name
            xml.owner_name_url user_path(video.user)
            unless video.user.league_staff?           
              xml.team_name video.user.team.title_name
              xml.team_url team_path(video.user.team)
            end
            if video.user.league_staff?
              xml.league_name video.user.league_name
              xml.league_url league_path(video.user.league)
            end
          else
            xml.user_name 'system'
          end
          xml.tags video.tags.collect(&:name).join(', ')
          xml.rating video.rating
          xml.rate_url "/ratings/rate/#{video.id}?type=VideoReel&rating="
        end
      end
    end
    xstr
  end
end
