class PagesController < BaseController
  
  before_filter :admin_required, :except => [:show]
  skip_before_filter :gs_login_required, :only => [:show]
  
  def index
    @pages = Page.find(:all)
  end
  
  def show
    if params[:permalink]
      @page = Page.find_by_permalink(params[:permalink])
      if @page.nil?
        if (current_user && current_user.admin?)
          redirect_to(:action => 'new', :permalink => params[:permalink]) and return
        else
          raise ActiveRecord::RecordNotFound, "Page not found" 
        end
      end
    else
      @page = Page.find(params[:id])
    end
    if (current_user && current_user.admin?)
      flash[:notice] = "<a href='/pages/edit/#{@page.id}'>Edit this page</a>"
    end
  end
  
  def new
    @page = Page.new
    @page.permalink= params[:permalink]
  end
  
  def create
    @page = Page.new(params[:page])
    if @page.save
      flash[:notice] = "Successfully created page."
      redirect_to @page
    else
      render :action => 'new'
    end
  end
  
  def edit
    @page = Page.find(params[:id])
  end
  
  def update
    @page = Page.find(params[:id])
    if @page.update_attributes(params[:page])
      flash[:notice] = "Successfully updated page."
      redirect_to pages_url
    else
      render :action => 'edit'
    end
  end
  
  def destroy
    @page = Page.find(params[:id])
    @page.destroy
    flash[:notice] = "Successfully destroyed page."
    redirect_to pages_url
  end
end
