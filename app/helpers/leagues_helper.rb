module LeaguesHelper

  def league_posts()
    Post.find(:all,
      :joins=>"JOIN users ON user_id = users.id",
      :conditions=>["users.league_id = ?", @league.id],
      :limit=>10
      )
  end
  
  def league_videos()
    VideoAsset.for_league(@league).all(:limit => 10, :order => 'updated_at DESC')
  end

  
end
