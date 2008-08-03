class PhotosController < BaseController

  before_filter :login_required
  session :cookie_only => false, :only => [:swfupload]
  protect_from_forgery :except => :swfupload

  

end
