class Channel < ActiveRecord::Base
  
  belongs_to :team
  belongs_to :league
  
  #has_many :channel_video, as => :video #,, :dependent => :destroy
  
  has_many :channel_videos
  
  def videos()
    channel_videos
  end
  
end