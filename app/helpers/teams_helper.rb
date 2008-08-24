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
  
  
  def team_videos()
    VideoAsset.for_team(@team).all(:limit => 10, :order => 'updated_at DESC')
  end
  
  
end
