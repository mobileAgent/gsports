class GameOfTheWeek
  # This is a wrapper around the admin users favorite videos
  def self.find
    videos = Favorite.user(User.admin.first).videos.all(:order => "created_at DESC", :limit => 6)
    # Add a last resort to keep the whole site from being borked
    if videos.size == 0
      videos << VideoAsset.ready.first
    end
    
    videos.inject([]) do |list,v|
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
