class MonikersController < BaseController

  before_filter :admin_required, :except => [:auto_complete_for_moniker_name]
  skip_before_filter :verify_authenticity_token, :only => [:auto_complete_for_moniker_name]
  auto_complete_for :moniker, :name
  
  # GET /monikers
  # GET /monikers.xml
  def index
    @monikers = Moniker.find(:all)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @monikers }
    end
  end

  # GET /monikers/1
  # GET /monikers/1.xml
  def show
    @moniker = Moniker.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @moniker }
    end
  end

  # GET /monikers/new
  # GET /monikers/new.xml
  def new
    @moniker = Moniker.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @moniker }
    end
  end

  # GET /monikers/1/edit
  def edit
    @moniker = Moniker.find(params[:id])
  end

  # POST /monikers
  # POST /monikers.xml
  def create
    @moniker = Moniker.new(params[:moniker])

    respond_to do |format|
      if @moniker.save
        flash[:notice] = 'Moniker was successfully created.'
        format.html { redirect_to(@moniker) }
        format.xml  { render :xml => @moniker, :status => :created, :location => @moniker }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @moniker.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /monikers/1
  # PUT /monikers/1.xml
  def update
    @moniker = Moniker.find(params[:id])

    respond_to do |format|
      if @moniker.update_attributes(params[:moniker])
        flash[:notice] = 'Moniker was successfully updated.'
        format.html { redirect_to(@moniker) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @moniker.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /monikers/1
  # DELETE /monikers/1.xml
  def destroy
    @moniker = Moniker.find(params[:id])
    @moniker.destroy

    respond_to do |format|
      format.html { redirect_to(monikers_url) }
      format.xml  { head :ok }
    end
  end
end
