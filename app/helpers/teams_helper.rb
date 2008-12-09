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
  
  # param :team may also be a League
  
  def most_recent_league_post(team=nil, opts={})
    team ||= @team
    league_id = nil
    
    case team
    when Team
      league_id = team.league_id
    when League
      league_id = team.id
    else
      raise "Type not supported: #{team.class}"
    end

    options = {
      :conditions=>["league_id = ?", league_id],
      :limit=>1,
      :order=>'published_at DESC'
    }.merge opts

    Post.first(options)

  end 
end
