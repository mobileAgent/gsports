class Channel < ActiveRecord::Base
  
  belongs_to :team
  belongs_to :league
  
  #has_many :channel_video, as => :video #,, :dependent => :destroy
  
  has_many :channel_videos
  
  def videos()
    channel_videos
  end
  
  def dockeys()
    channel_videos.collect{|cv| cv.video.dockey}.join(',')
  end
  
  
end