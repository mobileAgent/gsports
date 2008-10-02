class PurchaseOrdersController < BaseController

  before_filter :admin_required, :only => [:index]
  skip_before_filter :gs_login_required, :only => [:show, :new, :confirm, :create]
  skip_before_filter :billing_required, :only => [:show, :new, :confirm, :create]  

  def index
    @pos = PurchaseOrder.find(:all)
  end
  
  def new
    @po = PurchaseOrder.new(params[:purchase_order])
    @promotion = session[:promotion]
    
    # Purchase orders are made for the full retail price
    @cost = @po.user.role.plan.cost
    #@cost = (@promotion && !@promotion.cost.nil?) ? @promotion.cost : @po.user.role.plan.cost
  end
  
  def create
    @po = PurchaseOrder.new(params[:purchase_order])
    @promotion = session[:promotion]
    
    # Purchase orders are made for the full retail price
    @cost = @po.user.role.plan.cost
    #@cost = (@promotion && !@promotion.cost.nil?) ? @promotion.cost : @po.user.role.plan.cost
    
    if params[:confirm] == 'yes'
      if !params[:tos] || !params[:suba]
        @po.errors.add('', "Please accept the Terms of Service and the Subscriber Agreement") 
        render :action=>:confirm
      else
        @po.save!
        
        # Add the membership record here
        @po.user.make_member_by_invoice(@cost,@po,@promotion)

        #########################
        # If we have to auto-enable users when a po is submitted, here is how
        # @po.user.enabled = true
        # @po.user.activated_at = Time.now
        # @po.user.save!
        # self.current_user = @po.user # Log them in right now!
        # UserNotifier.deliver_welcome(@po.user)
        #########################
        
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
        po.accepted = true
        po.accepted_by = current_user
        po.accepted_at = Time.now
        
        # This may be a renewal...
        # so only set the user's enabled and activated fields for new enrollments
        if !po.user.enabled || po.user.activated_at.nil?
          po.user.enabled = true
          po.user.activated_at = Time.now
          po.user.save!
        end
        UserNotifier.deliver_welcome(po.user)
      }
    end
    @pos = PurchaseOrder.find(:all)
    render :action => 'index'
  end
    
  
end

