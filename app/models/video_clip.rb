class VideoClip < ActiveRecord::Base

  belongs_to :video_asset
  belongs_to :user

end
