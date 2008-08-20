class SearchController < BaseController
  
   skip_before_filter :verify_authenticity_token, :only => [ :quickfind ]
   before_filter :login_required, :except => [:sphinx_search, :teamfind]
   after_filter :protect_private_videos, :except => [:q, :teamfind]
  
   def sphinx_search
     @user = params[:user_id] ? User.find(params[:user_id]) : current_user
     if params[:search] and params[:search][:keyword]
       @videos = ThinkingSphinx::Search.search params[:search][:keyword], :per_page => 10, :page => params[:page]
     else
       @videos = ThinkingSphinx::Search.search '*', :per_page => 10, :page => params[:page]
     end    
   end

   # Video quickfind
   def quickfind
     @user = current_user
     cond = Caboose::EZ::Condition.new
     cond.append ['year(game_date) = ?',params[:season]]
     cond.append ['video_assets.league_id = ?', params[:league]]
     cond.append ['sport = ?', params[:sport]]
     cond.append ['teams.state_id = ?', params[:state]]
     cond.append ['teams.county_name = ?', params[:county_name]]
     cond.append ['public_video = ?', true]
     @video_assets = VideoAsset.paginate(:conditions => cond.to_sql, :page => params[:page], :order => 'video_assets.updated_at DESC', :include => [:team,:tags])
     @is_search_result = true
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
       render_name = 'my_videos'
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
       render :action => 'search'
     end
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
                          :page => (params[:page] || 1),
                          :order => :full_name)
   end
   
   def sphinx_search_blogs
     logger.debug "Running blog search for #{params[:search][:keyword]}"
     @posts = Post.search(params[:search][:keyword],
                          :conditions => { :published_as => 'live' },
                          :page => (params[:page] || 1),
                          :order => :published_at, :sort_mode => :desc)
   end

   def sphinx_search_videos
     @user = params[:user_id] ? User.find(params[:user_id]) : current_user
     if params[:search] && params[:search][:keyword]
       @video_assets = VideoAsset.search params[:search][:keyword], :limit => 10, :order => 'updated_at DESC'
       @video_clips = VideoClip.search params[:search][:keyword], :limit => 10, :order => 'updated_at DESC'
       @video_reels = VideoReel.search params[:search][:keyword], :limit => 10, :order => 'updated_at DESC'
     else
       @video_assets = VideoAsset.find :all, :limit => 10, :order => 'updated_at DESC'
       @video_clips = VideoClip.find :all, :limit => 10, :order => 'updated_at DESC'
       @video_reels = VideoReel.find :all, :limit => 10, :order => 'updated_at DESC'
     end
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
