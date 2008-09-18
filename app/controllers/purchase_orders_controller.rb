class PurchaseOrdersController < BaseController

  skip_before_filter :gs_login_required, :only => [:show, :new, :confirm, :create]


  
  def poshow
    @user = User.find(params[:userid].to_i)
    @item_no = @user.role_id
    if @user.team_staff?
      @entity = @user.team 
      @description = "Monthly Member Firm Subscription"
    else #if @user.league_staff?
      @entity = @user.league
      @description = "Monthly Sponsor Organiztion Subscription"
    end
    timestamp = Time.now.to_i
    @invoice_no = "#{@user.id}-#{timestamp}"
    render :layout => false
  end
  
  def new
    @po = PurchaseOrder.new(params[:purchase_order])
    render :layout => false
  end  
  
  def confirm
    @po = PurchaseOrder.new(params[:purchase_order])
    if @po.valid?
      render :layout => false
    else  
      render :action=>:new, :layout => false
    end
  end
  
  def create
    @po = PurchaseOrder.new(params[:purchase_order])
    @po.save!
    render :action=>:show, :layout => false, :id=>@po.id
  end
  
  def show
    @po = PurchaseOrder.find(params[:id].to_i)
    render :layout => false
  end
    
  
end

