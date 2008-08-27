# Methods added to this helper will be available to all templates in the application.

module ApplicationHelper

# These helpers come from community engine, but when coming
# from one of our templates (e.g. static/tos) they aren't included
# by default but if we still want the CE layout override then
# we need to force them in here
include BaseHelper
include ForumsHelper
include FriendshipsHelper
include PostsHelper
include SitemapHelper
include UsersHelper

  # For rjs pages to tickle the flash on the current page
  def flashnow(page,msg)
    page.select("#flash_notice span").first.replace("<span>#{msg}</span>")
    page.select("#flash_notice").first.show
  end

  def game_date(dtm)
    return '' if dtm.nil?
    return dtm.to_s(:game_date)
  end
  
  def human_date(dtm)
    return '' if dtm.nil?
    return dtm.to_s(:readable)
  end

  class Pair
    attr_accessor :name, :number
  end

  def cc_years
    arr = Array.new
    for i in (Time.now.year .. Time.now.year+12) do
      p = Pair.new
      p.name = i
      p.number = i
      arr << p
    end
    arr
  end

  def cc_months
    names = ["January","February","March","April","May","June",
             "July","August","September","October","November","December"]
    arr = Array.new
    for i in (0..11) do
      p = Pair.new
      p.name="#{names[i]} (#{i+1})"
      p.number=(i+1)
      arr << p
    end
    arr
  end

  def video_image_link(video)
    title = h(video.title.gsub(/\'/,''))
    target = '#'
    case video.class.to_s
    when VideoAsset.to_s
      target = video_asset_path(video)
    when VideoClip.to_s
      target = video_clip_path(video)
    when VideoReel.to_s
      target = video_reel_path(video)
    end
    
    vsrc = @vidavee.file_thumbnail_medium(video.thumbnail_dockey)
    link_to "<img src='#{vsrc}' title='#{title}' alt='Video'/>", target
  end

  def generate_link_for_message(item)
    if item.class.to_s == 'Comment'
      "/#{item.class.to_s.tableize}/show/#{item.id}"
    else
      "/#{item.class.to_s.tableize}/#{item.id}"
    end
  end
  
end
