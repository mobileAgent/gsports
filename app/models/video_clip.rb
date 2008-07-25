class VideoClip < ActiveRecord::Base

  belongs_to :video_asset
  belongs_to :user
  
  acts_as_commentable
  acts_as_taggable
  has_many :favorites, :as => :favoritable, :dependent => :destroy
  acts_as_activity :user
  
  # Every clip needs a title
  validates_presence_of :title

end
