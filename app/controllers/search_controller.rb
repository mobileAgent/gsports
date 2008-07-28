class SearchController < BaseController
  skip_before_filter :verify_authenticity_token, :only => [ :quickfind ]
  
  def quickfind
    cond = Caboose::EZ::Condition.new
    cond.append ['state_id = ?', params[:state]]
    cond.append ['county_name = ?', params[:county_name]]
    cond.append ['league_id = ?', params[:league]]
    cond.append ['sport = ?', params[:sport]]
    puts "********** Conditions #{cond.to_sql}"
    @video_assets = VideoAsset.find(:all, :conditions => cond.to_sql)
  end

  def search
  end

end
