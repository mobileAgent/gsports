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
    
  
end
