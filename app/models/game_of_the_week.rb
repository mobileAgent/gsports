class GameOfTheWeek
  # This is a wrapper around the admin users favorite videos
  def self.find
    videos = Favorite.user(User.find_by_email(ADMIN_EMAIL)).videos(:order => "updated_at DESC", :limit => 6)
    videos.inject([]) do |list,v|
      case v.favoritable_type
      when 'VideoAsset'
        list << VideoAsset.find(v.id)
      when 'VideoReel'
        list << VideoReel.find(v.id)
      when 'VideoClip'
        list << VideoClip.find(v.id)
      end
    end
  end
end
