class PPVAccess < ActiveRecord::Base

  belongs_to :user

  named_scope :for_user, lambda { |user| {:conditions => {:user_id=>user.id}, :order=>'id desc' } }

  named_scope :for_video, lambda { |video| {:conditions => {:video_id=>video.id}, :order=>'id desc' } }

  named_scope :active, :conditions => ['(expires is null or expires > ?)', Time.now]

  def video
    VideoAsset.find(video_id) rescue nil
  end

end
