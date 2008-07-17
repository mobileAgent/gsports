class SessionsController < BaseController
  skip_before_filter :verify_authenticity_token, :only => [:new, :create]
end
