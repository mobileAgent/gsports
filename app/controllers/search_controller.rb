class SearchController < BaseController
  
  skip_before_filter :verify_authenticity_token, :only => [ :quickfind ]
  skip_before_filter :gs_login_required, :only => [:teamfind]
  before_filter :vidavee_login
  after_filter :protect_private_videos, :except => [:teamfind]
  
   # Video quickfind
   def quickfind
     @user = current_user
     cond = Caboose::EZ::Condition.new
     cond.append ['year(game_date) = ?',params[:season]]
     cond.append ['video_assets.team_id = ?', params[:team]]
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
       xstr = @video.to_xml(:except => [:game_date, :created_at, :updated_at, :uploaded_file_path, :league_id, :team_id, :user_id, :delta, :video_type, :visiting_team_id, :home_team_id, :ignore_game_day, :gsan], :dasherize => false, :skip_types => true ) do |xml|
         xml.created_at @video.created_at.to_s(:readable)
         xml.updated_at @video.updated_at.to_s(:readable)
         xml.game_date @video.human_game_date_string
         xml.league_name @video.league_name
         xml.team_name @video.team_name
         if @video.user_id
           xml.user_name @video.user.full_name
         else
           xml.user_name 'system'
         end
         xml.visiting_team_name @video.visiting_team.name if @video.visiting_team_id
         xml.home_team_name @video.home_team.name if @video.home_team_id
         xml.tags @video.tags.collect(&:name).join(', ')
         xml.favorite_count @video.favorites.size
         xml.thumbnail_url @vidavee.file_thumbnail_medium(@video.dockey)
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
         xml.parent_id @video.video_asset_id
         xml.favorite_count @video.favorites.size
         xml.tags @video.tags.collect(&:name).join(', ')
         xml.thumbnail_url @vidavee.file_thumbnail_medium(@video.dockey)
         if @video.user_id
           xml.user_name @video.user.full_name 
           xml.team_name @video.user.team_name unless @video.user.league_staff?
           xml.league_name @video.user.league_name if @video.user.league_staff?
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
           xml.user_name @video.user.full_name 
           xml.team_name @video.user.team_name unless @video.user.league_staff?
           xml.league_name @video.user.league_name if @video.user.league_staff?
         else
           xml.user_name 'system'
         end
         xml.favorite_count @video.favorites.size
         xml.tags @video.tags.collect(&:name).join(', ')
         xml.thumbnail_url @vidavee.file_thumbnail_medium(@video.thumbnail_dockey)
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
