class CategoriesController < BaseController

  before_filter :login_required, :except => [:rss]

  def formus
    @categories = Category.find(:all)
  end     


end
