class PPVAccess < ActiveRecord::Base

  belongs_to :user

  named_scope :for_user, lambda { |user| {:conditions => {:user_id=>user.id}, :order=>'id desc' } }


  def video
    VideoAsset.find(video_id) rescue nil
  end

end
