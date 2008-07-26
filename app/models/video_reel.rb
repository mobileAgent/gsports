class VideoReel < ActiveRecord::Base
  
  belongs_to :user
  
  acts_as_commentable
  acts_as_taggable
  has_many :favorites, :as => :favoritable, :dependent => :destroy
  acts_as_activity :user
  
  # Every reel needs a title
  validates_presence_of :title
  
end