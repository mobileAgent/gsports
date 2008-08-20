module TeamsHelper
  
  def team_posts(team=nil)
    team ||= @team
    posts = Post.find(:all,
        :joins=>"JOIN users ON user_id = users.id",
        :conditions=>["users.team_id = ?", team.id],
        :limit=>10
        )
    posts ||= []
    posts
  end
  
  def team_videos()
    VideoAsset.for_team(@team).all(:limit => 10, :order => 'updated_at DESC')
    
  end
  
  
end
