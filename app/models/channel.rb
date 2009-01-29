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
  
  def self.layout_map()
    { 'left'=>0,'right'=>1,'top'=>2,'bottom'=>3 }
  end
  
  def self.layout_array()
    ['left','right','top','bottom']
  end
  
  def position()
    Channel.layout_array()[layout||0]
  end
  
end
