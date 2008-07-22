class VideoReel < ActiveRecord::Base
  
  belongs_to :user
  
  # Every reel needs a title
  validates_presence_of :title
end
