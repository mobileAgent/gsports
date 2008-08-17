class GameOfTheWeek
  
  # This is a wrapper around the admin users favorite videos
  def self.for_home_page
    video_favorites = Favorite.user(User.admin.first).videos.all(:order => "created_at DESC", :limit => 6)
    # Add a last resort to keep the whole site from being borked
    if video_favorites.size == 0
      video_favorites << VideoAsset.ready.first
    end
    convert_favorites_to_videos(video_favorites)
  end

  # Team staff favorites
  def self.for_team(team_id)
    team_staff_ids = User.team_staff(team_id).collect(&:id)
    favs = Favorite.featured_games(team_staff_ids)
    convert_favorites_to_videos(favs)
  end

  # League staff favorites
  def self.for_league(league_id)
    league_staff_ids = User.league_staff(league_id).collect(&:id)
    favs = Favorite.featured_games(league_staff_ids)
    convert_favorites_to_videos(favs)
  end

  private

  def self.convert_favorites_to_videos(video_favorites)
    video_favorites.inject([]) do |list,v|
      begin
        case v.favoritable_type
        when 'VideoAsset'
          list << VideoAsset.find(v.favoritable_id)
        when 'VideoReel'
          list << VideoReel.find(v.favoritable_id)
        when 'VideoClip'
          list << VideoClip.find(v.favoritable_id)
        end
      rescue
      end
      list
    end
  end
    
end
