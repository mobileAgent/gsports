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
end
