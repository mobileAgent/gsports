class Dashboard

  # Get recent uploads for the user's team and league, and if not
  # enough get any recent uploads to fill our quota
  def self.recent_uploads(user, limit = 5)
    videos = VideoAsset.ready.for_user(user).find(:all, :limit => limit)
    if videos.size < limit
      exclude = videos.collect(&:id)
      VideoAsset.ready.find(:all,
                            :conditions => ["id NOT IN (?) and public_video = ?",exclude,true],
                            :order => 'created_at DESC',
                            :limit => (limit-videos.size)).each { |v| videos << v}
    end
    videos
  end

  # Get popular video assets, reels and clips ordered
  # by how many times they have been favorited
  def self.popular_videos(user, limit = 5)
    f = Favorite.videos.find(:all,
                             :select => '*,count(1)',
                             :limit => limit,
                             :group => :favoritable_id,
                             :order => 'count(1) DESC, max(created_at) DESC')
    videos = []
    f.each do |fav|
      case fav.favoritable_type
      when VideoAsset.to_s
        videos << VideoAsset.find(fav.favoritable_id)
      when VideoClip.to_s
        videos << VideoClip.find(fav.favoritable_id)
      when VideoReel.to_s
        videos << VideoReel.find(fav.favoritable_id)
      end
    end
    videos
  end

  # Get recent clips and reels by friends of the user
  def self.network_recent(user, limit = 5)
    friend_ids = user.accepted_friendships.collect(&:friend_id)
    videos = VideoReel.find(:all,
                            :conditions => ['user_id in (?) and public_video = ?',friend_ids,true],
                            :order => 'created_at DESC',
                            :limit => limit)
    
    if (videos.size < limit)
      VideoClip.find(:all,
                     :conditions => ['user_id in (?) and public_video = ?',friend_ids,true],
                     :order => 'created_at DESC',
                     :limit => (limit - videos.size)).each { |v| videos << v }
    end
    videos
  end

  # Get favorite videos by my friends
  def self.network_favorites(user, limit = 5)
    friend_ids = user.accepted_friendships.collect(&:friend_id)
    f = Favorite.videos.find(:all,
                             :select => '*,count(1)',
                             :limit => limit,
                             :group => :favoritable_id,
                             :conditions => ['user_id in (?)',friend_ids],
                             :order => 'count(1) DESC, max(created_at) DESC')
    videos = []
    f.each do |fav|
      case fav.favoritable_type
      when VideoAsset.to_s
        videos << VideoAsset.find(fav.favoritable_id)
      when VideoClip.to_s
        videos << VideoClip.find(fav.favoritable_id)
      when VideoReel.to_s
        videos << VideoReel.find(fav.favoritable_id)
      end
    end
    videos
    
  end

end

  
