class TagsController < BaseController
  before_filter :login_required
  skip_before_filter :verify_authenticity_token, :only => [:auto_complete_for_tag_name]
end
