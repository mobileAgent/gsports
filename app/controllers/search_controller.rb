class SearchController < BaseController
  
  skip_before_filter :verify_authenticity_token, :only => [ :quickfind ]
  before_filter :login_required
  
  def quickfind
    cond = Caboose::EZ::Condition.new
    cond.append ['year(game_date) = ?',params[:season]]
    cond.append ['video_assets.league_id = ?', params[:league]]
    cond.append ['sport = ?', params[:sport]]
    cond.append ['teams.state_id = ?', params[:state]]
    cond.append ['teams.county_name = ?', params[:county_name]]
    @pages, @video_assets = paginate :video_assets, :conditions => cond.to_sql, :order => 'video_assets.updated_at DESC', :include => [:team,:tags]
  end

  def my_videos
    @video_assets = VideoAsset.for_user(current_user).find(:all, :limit => 10, :order => 'updated_at DESC')
    @video_clips = VideoClip.for_user(current_user).find(:all, :limit => 10, :order => 'updated_at DESC')
    @video_reels = VideoReel.for_user(current_user).find(:all, :limit => 10, :order => 'updated_at DESC')
  end

end
