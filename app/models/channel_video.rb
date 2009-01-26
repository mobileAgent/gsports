class ChannelVideo < ActiveRecord::Base

  belongs_to :channel
  belongs_to :video, :polymorphic => true

  
  validates_presence_of :video_type
  validates_presence_of :video_id
  validates_presence_of :channel_id
  
  validates_uniqueness_of :video_id, :scope => [:channel_id], :message => 'has already been added to this channel.'
  

end