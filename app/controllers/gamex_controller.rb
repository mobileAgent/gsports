class GamexController < BaseController
  
  
  def index
    @gamex_users = current_user.gamex_users
    if @gamex_users.size == 1
      redirect_to gamex_path(@gamex_users[0])
    end
  end
  
  
  def show
    
    @gamex_user = GamexUser.find( params[:id] )
      
  end
  
  def upload
    
    
  end
  
  
  def download
    
    @gamex_users = GamexUser.find(:all, :conditions => { :user_id => current_user.id } )
    @gamex_user = GamexUser.new(params[:gamex])
    
    if @gamex_users.size == 1
      @gamex_user = @gamex_users[0]
      @league = @gamex_users[0].league
    else
      if gamex_id = params[ :gamex_id ]
        @gamex_user = GamexUser.find( gamex_id )
        raise :access_denied if @gamex_user.user_id != current_user.id
      end
    end
    
    if (team_id = params[:team][:id]) and !team_id.empty?
      @team = Team.find(team_id)
    end
      
    if @gamex_user
      
      @teams = GamexUser.find(:all, :conditions=>{ :league_id=>1 }).collect() { |g| g.user.team }
      
      @video_assets = VideoAsset.paginate(:conditions => { :gamex_id=>@gamex_id }, :page => params[:page], :order => "created_at DESC", :include => :tags)
    end
    
    
    
  end
  
  
  def manage
    
  end

  
end # class

