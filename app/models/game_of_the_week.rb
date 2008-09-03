class GameOfTheWeek
  
  # This is a wrapper around the admin users favorite videos
  def self.for_home_page
    video_favorites = Favorite.user(User.admin.first).videos.all(:order => "created_at DESC", :limit => 6, :include => [:user, :favoritable])
    # Add a last resort to keep the whole site from being borked
    if video_favorites.size == 0
      video_favorites << VideoAsset.ready.first
    end
    video_favorites.collect(&:favoritable)
  end

  # Team staff favorites
  def self.for_team(team_id)
    team_staff_ids = User.team_staff(team_id).collect(&:id)
    favs = Favorite.featured_games(team_staff_ids).find(:all, :include => [:user, :favoritable])
    favs.collect(&:favoritable)
  end

  # League staff favorites
  def self.for_league(league_id)
    league_staff_ids = User.league_staff(league_id).collect(&:id)
    favs = Favorite.featured_games(league_staff_ids).find(:all, :include => [:user, :favoritable])
    favs.collect(&:favoritable)
  end
end
