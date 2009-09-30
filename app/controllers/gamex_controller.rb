class GamexController < BaseController
  
  before_filter :in_gamex_content
  before_filter :find_gamex_user

  
  def index
    redirect_to '/gamex/download'
    return
    
    @gamex_users = current_user.gamex_users
    if @gamex_users.size == 1
      redirect_to gamex_path(@gamex_users[0])
    end
  end
  
  
  def show
    
    @gamex_user = GamexUser.find( params[:id] )
      

    
      
  end
  
  
  def download
    

    
    if @gamex_user

      @teams = @gamex_user.teams()
      
      conditions = { 
        :gamex_league_id => @gamex_user.league.id,
        :video_status => 'ready'
      }
      
  	  if params[:team] and (team_id = params[:team][:id]) and !team_id.empty?
  	    @team = Team.find(team_id)
        #@video_assets = VideoAsset.paginate(:conditions => { :gamex_league_id=>@gamex_user.league.id, :team_id=>team_id }, :page => params[:page], :order => "created_at DESC", :include => :tags)
  	    conditions[:team_id]= team_id 
  	  end
  	  
	    @video_assets = VideoAsset.paginate(:conditions => conditions, :page => params[:page], :order => "created_at DESC", :include => :tags)
      
    end
    
    
  end
  

  def history
    case params[:scope]
    when 'uploads'
      @uploads = VideoHistory.uploads.paginate(:page => params[:page])
    when 'views'
      @views = VideoHistory.views.paginate(:page => params[:page], :per_page=>3)
    else
      @uploads = VideoHistory.uploads.summary
      @views = VideoHistory.views.summary
    end
  end


  def in_gamex_content
    @render_gamex_tips = true
    @render_gamex_menu = true
  end
  
  def find_gamex_user
    @gamex_users = GamexUser.for_user(current_user) #find(:all, :conditions => { :user_id => current_user.id } )

    if @gamex_users.size == 1
      @gamex_user = @gamex_users.first
    else
      if params[ :gamex_user ] and gamex_id = params[ :gamex_user ][ :id ]
        @gamex_user = GamexUser.find( gamex_id )
        unless @gamex_user.user_id == current_user.id
          access_denied and return
        end
      end
    end
  end

  
end # class

