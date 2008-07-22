class VideoClip < ActiveRecord::Base

  belongs_to :video_asset
  belongs_to :user
  
  acts_as_commentable
  acts_as_taggable
  belongs_to :favoritable, :polymorphic => true
  
  # Every clip needs a title
  validates_presence_of :title

end
