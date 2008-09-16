class SearchController < BaseController
  
  skip_before_filter :verify_authenticity_token, :only => [ :quickfind ]
  skip_before_filter :gs_login_required, :only => [:teamfind,:update_teamfind_counties,:update_teamfind_cities]
  before_filter :vidavee_login
  after_filter :protect_private_videos, :except => [:teamfind]
  
  # Video quickfind
  def quickfind
    @user = current_user
    cond = Caboose::EZ::Condition.new
    if ! params[:season].blank?
      cond.append ['year(game_date) = ? or game_date_str like ?',params[:season],"#{params[:season]}%"]
    end
    cond.append ['? in (video_assets.team_id,video_assets.home_team_id,video_assets.visiting_team_id)', params[:team]]
    cond.append ['sport = ?', params[:sport]]
    cond.append ['teams.state_id = ?', params[:state]]
    cond.append ['teams.county_name = ?', params[:county_name]]
    cond.append ['public_video = ?', true]
    @video_assets = VideoAsset.paginate(:conditions => cond.to_sql, :page => params[:page], :order => 'video_assets.updated_at DESC', :include => [:team,:tags])
    @is_search_result = true
    @search_result_size = @video_assets.size
    @title = 'Video Quickfind Results'
    render :action => 'my_videos'
  end

  def quickfind_select_state
    state = (params[:state] || 0).to_i
    counties = state > 0 ? Team.counties(state) : @quickfind_counties
    schools = state > 0 ? Team.find(:all, :conditions=>{:state_id=>state}, :order => 'name ASC') : @quickfind_schools

    render :update do |page|
      page.replace_html 'quickfind_counties', :partial => 'quickfind_counties', :object => counties
      page.replace_html 'quickfind_schools',  :partial => 'quickfind_schools',  :object => schools
    end
  end

  def quickfind_select_county
    county = (params[:county] || "")
    schools = !county.empty? ? Team.find(:all, :conditions=>{:county_name=>county}, :order => 'name ASC') : @quickfind_schools
    
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
    
    if @category == 1 || @category == 0
      logger.debug "Routing search to video category"
      @videos = sphinx_search_videos
      @title = 'Search Results'
      render_name = 'video_listing'
    end
    if @category == 2 || @category == 0
      logger.debug "Routing search to user category"
      @users = sphinx_search_users
      render_name = 'user_listing'
    end
    if @category == 3 || @category == 0
      logger.debug "Routing search to blog category"
      @posts = sphinx_search_blogs
      render_name = 'post_listing'
    end
    
    if @category == 10
      logger.debug "Routing search to team category"
      @users = activerecord_search_team
      render_name = 'user_listing'
    end
    
    if @category == 11
      logger.debug "Routing search to league category"
      @users = activerecord_search_league
      render_name = 'user_listing'
    end

    if @category == 13
      logger.debug "Routing search to friend category"
      @users = sphinx_search_friends
      render_name = 'user_listing'
    end


    # Search all categories
    if @category > 0
      
      render :action => render_name and return
    else
      # The search layout looks dumb if two columns are empty
      if @users.size + @posts.size == 0
        render :action => 'video_listing'
      elsif @users.size + @videos.size == 0
        render :action => 'post_listing'
      elsif @posts.size + @videos.size == 0
        render :action => 'user_listing'
      else
        render :action => 'search'
      end
    end
  end

  # The flash player uses this to get metadata for
  # any video object by dockey
  def d
    dockey = params[:dockey]
    @video = VideoAsset.find_by_dockey(dockey)
    if @video
      xstr = @video.to_xml(:except => [:game_date, :game_date_str, :created_at, :updated_at, :uploaded_file_path, :league_id, :team_id, :user_id, :delta, :video_type, :visiting_team_id, :home_team_id, :ignore_game_day, :ignore_game_month, :gsan, :internal_notes], :dasherize => false, :skip_types => true ) do |xml|
        xml.created_at @video.created_at.to_s(:readable)
        xml.updated_at @video.updated_at.to_s(:readable)
        xml.game_date @video.human_game_date_string
        xml.league_name @video.league_name if @video.league_id
        xml.team_name @video.team.title_name if @video.team_id
        if @video.league_video?
          xml.owner_name @video.league_name
          xml.owner_name_url league_path(@video.league)
        elsif (@video.team_id?)
          xml.owner_name @video.team.title_name
          xml.owner_name_url team_path(@video.team)
        else
          xml.owner_name @video.user.full_name
          xml.owner_name_url user_path(@video.user_id)
        end
        if @video.user_id
          xml.user_name @video.user.full_name
        else
          xml.user_name 'system'
        end
        if @video.visiting_team_id
          xml.visiting_team_name @video.visiting_team.title_name 
          xml.visiting_team_url team_path(@video.visiting_team)
        end
        if @video.home_team_id
          xml.home_team_name @video.home_team.title_name
          xml.home_team_url team_path(@video.home_team)
        end
        xml.tags @video.tags.collect(&:name).join(', ')
        xml.favorite_count @video.favorites.size
        xml.thumbnail_url @vidavee.file_thumbnail_medium(@video.dockey)
        xml.rating 1
        xml.type 'VideoAsset'
      end
      render :xml => xstr and return
    end
    @video = VideoClip.find_by_dockey(dockey)
    if @video
      xstr = @video.to_xml(:except => [:created_at, :updated_at, :user_id, :delta, :video_asset_id], :dasherize => false, :skip_types => true ) do |xml|
        xml.type 'VideoClip'
        xml.created_at @video.created_at.to_s(:readable)
        xml.updated_at @video.updated_at.to_s(:readable)
        xml.parent_dockey @video.video_asset.dockey
        xml.parent_name @video.video_asset.title
        xml.parent_url video_asset_path(@video.video_asset_id)
        xml.favorite_count @video.favorites.size
        xml.tags @video.tags.collect(&:name).join(', ')
        xml.thumbnail_url @vidavee.file_thumbnail_medium(@video.dockey)
        xml.rating 1
        if @video.user_id
          xml.owner_name @video.user.full_name
          xml.owner_name_url user_path(@video.user)
          unless @video.user.league_staff?
            xml.team_name @video.user.team.title_name 
            xml.team_url team_path(@video.user.team)
          end
          if @video.user.league_staff?
            xml.league_name @video.user.league_name
            xml.league_url league_path(@video.user.league)
          end
        else
          xml.user_name 'system'
        end
      end
      render :xml => xstr and return
    end
    @video = VideoReel.find_by_dockey(dockey)
    if @video
      xstr = @video.to_xml(:except => [:created_at, :updated_at, :user_id, :delta], :dasherize => false, :skip_types => true) do |xml|
        xml.type 'VideoReel'
        xml.created_at @video.created_at.to_s(:readable)
        xml.updated_at @video.updated_at.to_s(:readable)
        if @video.user_id
          xml.owner_name @video.user.full_name
          xml.owner_name_url user_path(@video.user)
          unless @video.user.league_staff?           
            xml.team_name @video.user.team.title_name
            xml.team_url team_path(@video.user.team)
          end
          if @video.user.league_staff?
            xml.league_name @video.user.league_name
            xml.league_url league_path(@video.user.league)
          end
        else
          xml.user_name 'system'
        end
        xml.favorite_count @video.favorites.size
        xml.tags @video.tags.collect(&:name).join(', ')
        xml.thumbnail_url @vidavee.file_thumbnail_medium(@video.thumbnail_dockey)
        xml.rating 1
      end
      render :xml => xstr and return
    end
    render :inline => '<video-asset>not found</video-asset>' and return
  end
  
  def my_videos
    @user = params[:user_id] ? User.find(params[:user_id]) : current_user
    
    @video_assets = VideoAsset.for_user(@user).all(:limit => 10, :order => 'updated_at DESC')
    @video_clips = VideoClip.for_user(@user).all(:limit => 10, :order => 'updated_at DESC')
    @video_reels = VideoReel.for_user(@user).all(:limit => 10, :order => 'updated_at DESC')
  end
  
  # This is not as straight-forward as video assets where the user_id is the
  # current user. That has it's place, but we need more.
  def my_video_assets
    @user = params[:user_id] ? User.find(params[:user_id]) : current_user
    @video_assets = VideoAsset.for_user(@user).paginate(:page => params[:page], :order => 'updated_at DESC')
    render:action => "my_videos"
  end
  
  def my_video_clips
    @user = params[:user_id] ? User.find(params[:user_id]) : current_user
    @video_clips = VideoClip.for_user(@user).paginate(:page => params[:page], :order => 'updated_at DESC')
    render:action => "my_videos"
  end
  
  def my_video_reels
    @user = params[:user_id] ? User.find(params[:user_id]) : current_user
    @video_reels = VideoReel.for_user(@user).paginate(:page => params[:page], :order => 'updated_at DESC')
    render:action => "my_videos"
  end
  
  def team_video_assets
    @user = current_user
    @team = Team.find(params[:team_id])
    @title = @team.name
    @video_assets = VideoAsset.for_team(@team).paginate(:page => params[:page], :order => 'updated_at DESC')
    render:action => "my_videos"
  end

  def league_video_assets
    @user = current_user
    @league = League.find(params[:league_id])
    @title = @league.name
    @video_assets = VideoAsset.for_league(@league).paginate(:page => params[:page], :order => 'updated_at DESC')
    render:action => "my_videos"
  end

  
  def teamfind
    cond = Caboose::EZ::Condition.new
    cond.append ['state_id = ?',params[:state]]
    cond.append ['county_name = ?', params[:county]]
    cond.append ['city = ?', params[:city]]
    #cond.append ['name = ?', params[:name]]
    
    @teams = Team.paginate(:conditions => cond.to_sql, :page => params[:page], :order => 'teams.name DESC')
    logger.debug "Found #{@teams.total_entries} entries on #{@teams.total_pages} pages"
  end
  
  def update_teamfind_counties
    state = (params[:state] || 0).to_i
    teamfind_counties = state > 0 ? Team.counties(state) : @quickfind_counties
    quickfind_cities = state > 0 ? Team.find(:all,:select => "DISTINCT city",:conditions => "state_id = '#{state}' AND city IS NOT NULL",:order => 'city ASC') : @quickfind_cities
      
    render :update do |page|
      page.replace_html 'teamfind_counties', :partial => 'teamfind_counties', :object => teamfind_counties
      page.replace_html 'teamfind_cities',   :partial => 'teamfind_cities',   :object => quickfind_cities
    end
  end
  
  def update_teamfind_cities
    county = (params[:county] || "")
    teamfind_cities = !county.empty?  ? Team.cities(county) : @quickfind_cities

    render :update do |page|
      page.replace_html 'teamfind_cities',   :partial => 'teamfind_cities',   :object => teamfind_cities
    end
  end
  

  protected

  def sphinx_search_users
    logger.debug "Running user search for #{params[:search][:keyword]}"
    @users = User.search(params[:search][:keyword],
                         :conditions => { :profile_public => 1 },
                         :per_page => 30,
                         :page => (params[:page] || 1),
                         :order => :full_name)
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


  def protect_private_videos
    # Remove private video assets from results
    if (@video_assets && @video_assets.any? && current_user && (! current_user.admin? ))
      @video_assets.reject!{|v| v.public_video == false && v.user_id != current_user.id}
    end
    
    # Remove private clips from results
    if (@video_clips && @video_clips.any? && current_user && (! current_user.admin? ))
      @video_clips.reject!{|v| v.public_video == false && v.user_id != current_user.id}
    end
    
    # Remove private reels from results
    if (@video_reels && @video_reels.any? && current_user && (! current_user.admin?) )
      @video_reels.reject!{|v| v.public_video == false && v.user_id != current_user.id}
    end
    true
  end

end
