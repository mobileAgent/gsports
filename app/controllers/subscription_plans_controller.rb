class SubscriptionPlansController < BaseController
  
  before_filter :admin_required
  
  # GET /subscription_plans
  # GET /subscription_plans.xml
  def index
    @subscription_plans = SubscriptionPlan.find(:all)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @subscription_plans }
    end
  end

  # GET /subscription_plans/1
  # GET /subscription_plans/1.xml
  def show
    @subscription_plan = SubscriptionPlan.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @subscription_plan }
    end
  end

  # GET /subscription_plans/new
  # GET /subscription_plans/new.xml
  def new
    @subscription_plan = SubscriptionPlan.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @subscription_plan }
    end
  end

  # GET /subscription_plans/1/edit
  def edit
    @subscription_plan = SubscriptionPlan.find(params[:id])
  end

  # POST /subscription_plans
  # POST /subscription_plans.xml
  def create
    @subscription_plan = SubscriptionPlan.new(params[:subscription_plan])

    respond_to do |format|
      if @subscription_plan.save
        flash[:notice] = 'SubscriptionPlan was successfully created.'
        format.html { redirect_to(@subscription_plan) }
        format.xml  { render :xml => @subscription_plan, :status => :created, :location => @subscription_plan }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @subscription_plan.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /subscription_plans/1
  # PUT /subscription_plans/1.xml
  def update
    @subscription_plan = SubscriptionPlan.find(params[:id])

    respond_to do |format|
      if @subscription_plan.update_attributes(params[:subscription_plan])
        flash[:notice] = 'SubscriptionPlan was successfully updated.'
        format.html { redirect_to(@subscription_plan) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @subscription_plan.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /subscription_plans/1
  # DELETE /subscription_plans/1.xml
  def destroy
    @subscription_plan = SubscriptionPlan.find(params[:id])
    @subscription_plan.destroy

    respond_to do |format|
      format.html { redirect_to(subscription_plans_url) }
      format.xml  { head :ok }
    end
  end
end
