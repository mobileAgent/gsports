module TeamsHelper
  
  def team_posts(team=nil, opts={})
    team ||= @team
    
    options = {
      #:joins=>"JOIN users ON user_id = users.id",
      #:conditions=>["users.team_id = ?", team.id],
      :conditions=>["team_id = ?", team.id],
      :limit=>10,
      :order=>'published_at DESC'
    }.merge opts
    
    posts = Post.find(:all, options)
    
    posts ||= []
  end
  
  def most_recent_league_post(team=nil, opts={})
    team ||= @team

    options = {
      :conditions=>["league_id = ?", team.league_id],
      :limit=>1,
      :order=>'published_at DESC'
    }.merge opts

    Post.first(options)

  end 
end
