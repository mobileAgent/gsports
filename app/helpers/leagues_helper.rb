module LeaguesHelper

  def league_posts(league=nil, opts={})
    league ||= @league
    
    options = {
      #:joins=>"JOIN users ON user_id = users.id",
      #:conditions=>["users.league_id = ?", league.id],
      :conditions=>["league_id = ?", league.id],
      :limit=>10
    }.merge opts
    
    posts = Post.find(:all, options)
    
    posts ||= []
  end
  
  
  def league_videos()
    VideoAsset.for_league(@league).all(:limit => 10, :order => 'updated_at DESC')
  end

  
end
