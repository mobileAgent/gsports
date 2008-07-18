class PhotosController < BaseController

  session :cookie_only => false, :only => [:swfupload]
  protect_from_forgery :except => :swfupload

end
