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
  
  def create
    @po = PurchaseOrder.new(params[:purchase_order])
    @promotion = session[:promotion]
    @cost = (@promotion && @promotion.cost) ? @promotion.cost : @po.user.role.plan.cost
    
    if params[:confirm] == 'yes'
      if !params[:tos] || !params[:suba]
        @po.errors.add('', "Please accept the Terms of Service and the Subscriber Agreement") 
        render :action=>:confirm
      else
        @po.save!
        render :action=>:show, :layout => false, :id=>@po.id
      end
    else    
      raise(ActiveRecord::RecordInvalid.new(@po)) if !@po.valid?
      render :action=>:confirm
    end
    
  rescue ActiveRecord::RecordInvalid => e  
    render :action => 'new'
  end
  
  def show
    @po = PurchaseOrder.find(params[:id].to_i)
    render :layout => false
  end
  
  def activate
    pos = params[:pos]
    if pos
      pos.each { |poid|
        po = PurchaseOrder.find(poid.to_i)
        po.user.enabled = true
        po.user.activated_at = Time.now
        po.user.save!
        UserNotifier.deliver_welcome(po.user)
      }
    end
    @pos = PurchaseOrder.find(:all)
    render :action => 'index'
  end
    
  
end

