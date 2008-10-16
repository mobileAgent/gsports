class PurchaseOrdersController < UsersController

  before_filter :admin_required, :only => [:index, :activate]
  skip_before_filter :gs_login_required, :only => [:show, :new, :confirm, :create]
  skip_before_filter :billing_required, :only => [:show, :new, :confirm, :create]  

  # Since we are extending the UsersController, make sure we skip filters that are set up there
  skip_before_filter :find_user, :only => [:show, :new, :create]  

  def index
    @pos = PurchaseOrder.find(:all)
  end
  
  def new
    session[:purchase_order] = nil
    @po = PurchaseOrder.new(params[:purchase_order])
    @po.user = current_user || reg_user_from_cookie
    
    unless session[:promo_id].nil?
      @promotion = Promotion.find(session[:promo_id].to_i)
    end    

    # Purchase orders are made for the full retail price
    @cost = @po.user.role.plan.cost
    #@cost = (@promotion && !@promotion.cost.nil?) ? @promotion.cost : @po.user.role.plan.cost
  end
  
  def create
    @user = current_user || reg_user_from_cookie 
    # Purchase orders are made for the full retail price
    @cost = @user.role.plan.cost

    unless session[:promo_id].nil?
      @promotion = Promotion.find(session[:promo_id].to_i)
    end    
    
    # Catch the case when the user clicks the Print button multiple times
    if current_user.nil? && session[:purchase_order]
      logger.debug "Got Purchase Order off the session"
      @po = session[:purchase_order]
      @po.user = @user
      redirect_to :action=>:show, :layout => false
    else
      logger.debug "Reading purchase order params from form..."
      @po = PurchaseOrder.new params[:purchase_order]
      @po.user = @user
      logger.debug "Done reading purchase order params from form..."
      
      if params[:confirm] == 'yes'
        if !params[:tos] || !params[:suba]
          @po.errors.add('', "Please accept the Terms of Service and the Subscriber Agreement") 
          render :action=>:confirm
        else
          
          @po.due_date = Time.now + 2.weeks
          if @promotion && @promotion.period_days
            @po.due_date += @promotion.period_days.days
          end

          #NOTE: this is duplicate code from submit_billing          
          if reg_team_from_cookie 
           logger.info "* Saving TEAM"
            @team = reg_team_from_cookie
            @team.save!
            @user.team = @team;
            @user.league = @team.league;
          end
          if reg_league_from_cookie
            logger.info "* Saving LEAGUE"
            @league = reg_league_from_cookie
            @league.save!
            @user.league = @league;
          end
        
          # fallback league and team settings
          @user.league = User.admin.first.league if @user.league.nil?
          @user.team = User.admin.first.team if @user.team.nil?

          logger.debug "* Saving user record"
          @user.save!

          logger.debug "* Saving purchase order"
          @po.user = @user
          @po.save!
  
          # Add the membership record here
          logger.debug "* Saving user membership"
          @user.make_member_by_invoice(@cost,@po,@promotion)
     
  
          #########################
          # If we have to auto-enable users when a po is submitted, here is how
          # @po.user.enabled = true
          # @po.user.activated_at = Time.now
          # @po.user.save!
          # self.current_user = @po.user # Log them in right now!
          # UserNotifier.deliver_welcome(@po.user)
          #########################
          
          # Put the po on the session, otherwise this user has no access to it
          # Also, it is used to catch the case when the user 
          # clicks the Print button multiple times
          session[:purchase_order] = @po
          
          redirect_to :action=>:show, :layout => false
        end
      else    
        #raise(ActiveRecord::RecordInvalid.new(@po)) if !@po.valid?
        render :action=>:confirm
      end
    end    
  rescue ActiveRecord::RecordInvalid => e  
    render :action => 'new'
  end
  
  def show
    if current_user.nil?
      logger.debug "Not logged in..."
      @po = session[:purchase_order]
    else
      logger.debug "Looking up po by id"
      @po = PurchaseOrder.find(params[:id].to_i)
  
      if @po
        unless current_user.admin? || current_user.id == @po.user_id
          render :action => 'private'
        end
      end
    end
    
    @promotion = @po.membership ? @po.membership.promotion : nil
    @user = @po.user
    @cost = @user.role.plan.cost
    
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

