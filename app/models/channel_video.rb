class ChannelVideo < ActiveRecord::Base

  belongs_to :channel
  belongs_to :video, :polymorphic => true

end