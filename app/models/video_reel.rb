class VideoReel < ActiveRecord::Base
  
  belongs_to :user
  
  acts_as_commentable
  acts_as_taggable
  belongs_to :favoritable, :polymorphic => true
  
  # Every reel needs a title
  validates_presence_of :title
end
