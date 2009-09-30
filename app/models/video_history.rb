class VideoHistory < ActiveRecord::Base

  belongs_to :user
  belongs_to :team
  belongs_to :video_asset


  UPLOADED   = 'U'
  VIEWED     = 'V'
  DOWNLOADED = 'D'
  

  named_scope :views, :conditions=>["activity_type in (?,?)", VIEWED, DOWNLOADED], :select=>'*, count(video_asset_id) as views', :group=>:video_asset_id, :order=>'id desc'

  named_scope :uploads, :conditions=>{:activity_type => UPLOADED}, :order=>'id desc'

  named_scope :summary, :limit=>10



  def game_title_small
      game_title.gsub(/\,\s+(\d{2}\-\d{2}\-\d{4})/,'')
  end



  class << self
    def uploaded(video_asset)
      track_video(video_asset, video_asset.user_id, UPLOADED)
    end
    
    def viewed(video_asset,user)
      track_video(video_asset, user, VIEWED)
    end
    
    def download(video_asset,user)
      track_video(video_asset, user, DOWNLOADED)
    end
          
    private
    def track_video(video_asset,user,activity_type)
      vh = VideoHistory.new
      vh.video_asset_id = video_asset.id
      vh.user_id = user.id
      vh.team_id = video_asset.team_id
      vh.activity_type = activity_type
      vh.save!
    end
  end
end
