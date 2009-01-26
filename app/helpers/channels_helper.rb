module ChannelsHelper
  
  def channel_publish_video_path(video_listing)
    "/channels/add/?channel_video[video_type]=#{video_listing.class}&channel_video[video_id]=#{video_listing.id}"
  end
  
end
