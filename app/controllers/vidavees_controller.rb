class VidaveesController < BaseController

  # Only admin can edit this table
  # Those just wishing to use the values, see vidapi_controller
  before_filter :admin_required
  
  # GET /vidavees
  # GET /vidavees.xml
  def index
    @vidavees = Vidavee.all
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @vidavees }
    end
  end

  # GET /vidavees/1
  # GET /vidavees/1.xml
  def show
    @vidavee = Vidavee.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @vidavee }
    end
  end

  # GET /vidavees/new
  # GET /vidavees/new.xml
  def new
    @vidavee = Vidavee.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @vidavee }
    end
  end

  # GET /vidavees/1/edit
  def edit
    @vidavee = Vidavee.find(params[:id])
  end

  # POST /vidavees
  # POST /vidavees.xml
  def create
    @vidavee = Vidavee.new(params[:vidavee])

    respond_to do |format|
      if @vidavee.save
        flash[:notice] = 'Vidavee was successfully saved.'
        format.html { redirect_to(@vidavee) }
        format.xml  { render :xml => @vidavee, :status => :created, :location => @vidavee }
        # Destroy any copy in cache
        Rails.cache.delete('vidavee')
        puts 'Need to expire all user vidavee login tokens'
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @vidavee.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /vidavees/1
  # PUT /vidavees/1.xml
  def update
    @vidavee = Vidavee.find(params[:id])

    respond_to do |format|
      if @vidavee.update_attributes(params[:vidavee])
        flash[:notice] = 'Vidavee was successfully updated.'
        format.html { redirect_to(@vidavee) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @vidavee.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /vidavees/1
  # DELETE /vidavees/1.xml
  def destroy
    @vidavee = Vidavee.find(params[:id])
    @vidavee.destroy

    respond_to do |format|
      format.html { redirect_to(vidavees_url) }
      format.xml  { head :ok }
    end
  end
end
