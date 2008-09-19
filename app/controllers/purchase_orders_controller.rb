class PurchaseOrdersController < BaseController

  before_filter :admin_required, :only => [:index]
  skip_before_filter :gs_login_required, :only => [:show, :new, :confirm, :create]


  def index
    @pos = PurchaseOrder.find(:all)
  end
  
  def new
    @po = PurchaseOrder.new(params[:purchase_order])
    
    @promotion = session[:promotion]
    @cost = (@promotion && @promotion.cost) ? @promotion.cost : @po.user.role.plan.cost
    
  end  
  
  def xconfirm
    @po = PurchaseOrder.new(params[:purchase_order])
    if !@po.valid?
      render :action=>:new
    end
  end
  
  def create
    @po = PurchaseOrder.new(params[:purchase_order])
    if params[:confirm]
      raise(RecordNotSaved)
      @po.save!
      render :action=>:show, :layout => false, :id=>@po.id
    else
      raise(RecordNotSaved) if !@po.valid?
      render :action=>:confirm
    end
    
  rescue ActiveRecord::RecordInvalid => e
    render :action => 'new'
  end
  
  def show
    @po = PurchaseOrder.find(params[:id].to_i)
    render :layout => false
  end
    
  
end

