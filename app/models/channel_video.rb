class ChannelVideo < ActiveRecord::Base

  belongs_to :channel
  belongs_to :video, :polymorphic => true

  
  validates_presence_of :video_type
  validates_presence_of :video_id
  validates_presence_of :channel_id
  
  validates_uniqueness_of :video_id, :scope => [:channel_id], :message => 'has already been added to this channel.'
  
  
  def validate
    channel = Channel.find(channel_id)
    limit = channel.publish_limit
    if limit and (channel.videos.size > limit)
      errors.add_to_base("You've already published the maximum of #{limit} videos allowed for this channel. You must remove one or more videos before you can add more.")
    end
  end
  

end