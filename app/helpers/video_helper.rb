module VideoHelper
  
  def video_tab_name(video)
    case video
    when VideoClip
      'Clip'
    when VideoReel
      'Reel '
    when VideoUser
      'User Video'
    else
      'Full Game'
    end
  end
  
  def video_path(video)
    case video
    when VideoClip
      user_video_clip_path(video.user_id,video)
    when VideoReel
      user_video_reel_path(video.user_id,video)
    when VideoUser
      user_video_user_path(video.user_id,video)
    else
      video_asset_path(video)
    end
  end
  
  def edit_video_path(video)
    case video
    when VideoClip
      edit_user_video_clip_path(video.user_id,video)
    when VideoReel
      edit_user_video_reel_path(video.user_id,video)
    when VideoUser
      edit_user_video_user_path(video.user_id,video)
    else
      edit_video_asset_path(video)
    end
  end
  
  def video_controller(video)
    case video
    when VideoClip
      'video_clips'
    when VideoReel
      'video_reels'
    when VideoUser
      'video_users'
    else
      'video_assets'
    end
  end
  
  
end