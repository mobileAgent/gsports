class Channel < ActiveRecord::Base
  
  belongs_to :team
  belongs_to :league
  
  #has_many :channel_video, as => :video #,, :dependent => :destroy
  
  has_many :channel_videos
  
  FIELD_NAME_OVERRIDES = {  
      :thumb_count => '',  
      :thumb_span => ''
    }

   
  def self.human_attribute_name(attr)  
     
    FIELD_NAME_OVERRIDES[attr.to_sym] || super  
  end

  
  def x_validate
    
    limit = publish_limit()
    target = thumb_count.to_i * thumb_span.to_i
    if limit and (target > limit)
      errors.add(:thumb_span, "Rows x Columns must be less than #{limit}.")
      errors.add(:thumb_count, "You are allowed to publish a maximum of #{limit} videos to this channel.")
    end
    
  end
  
  
  
  def videos()
    channel_videos
  end
  
  def dockeys()
    dockeys = channel_videos.collect{|cv| cv.video.dockey if cv.video}
    dockeys.delete(nil)
    dockeys.join(',')
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
  
  def publish_limit
    limit = nil
    limit = team.publish_limit if team_id
    limit = league.publish_limit if league_id
    limit
  end
  
end
