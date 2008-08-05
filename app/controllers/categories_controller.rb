class CategoriesController < BaseController

  before_filter :login_required, :except => [:rss]
  
end
