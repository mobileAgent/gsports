class ReportsController < BaseController

  skip_before_filter :verify_authenticity_token, :only => [:clips ]

  before_filter  do  |c| c.find_staff_scope(Permission::REPORT) end


  sortable_attributes 'reports.id', 'reports.name'

  def index
    
    if @scope
      @reports = Report.for_owner(@scope).paginate(:all, :order => sort_order, :page=>params[:page])
    end

  end

  def new
    @report = Report.new

  end

  def pop_new
    @report = Report.new

    render :update do |page|
      page.replace_html 'dialog', :partial => 'pop_new'
    end

  end

  def create
    @report = Report.new(params[:report])

    @report.owner = @scope
    @report.author = current_user

    if @report.save
      redirect_to build_reports_path(:id => @report.id)
    else
      render :action => "new"
    end
  end

  def edit
    @report = Report.find(params[:id])
  end

  def build
    @report = Report.find(params[:id])

    @library = []
    @tree_detail = []

    GamexUser.for_user(current_user).each() do |gamex|


	    vids = VideoAsset.find(:all,
        :conditions => {
          :gamex_league_id => gamex.league.id,
          :video_status => 'ready'
        },
        :order => "created_at DESC"
      )
      
      items = []
      vids.each() { |video|
        item = {}
        item[:id] = video.id
        item[:txt] = video.title
        item[:onclick] = 'gs_reports_loadclips'
        items << item
      }
      tree_root = {
        :id=>"gamex #{gamex.league.id}",
        :txt => gamex.league.name,
        :items => items,
      }
      @tree_detail << tree_root

    end

  end

  def update
    @report = Report.find(params[:id])

    status = @report.update_attributes(params[:report])

    if status
      redirect_to reports_path(:scope_select=>@scope)
    else
      render :action => "edit"
    end

  end

  def clips
    @video_asset = VideoAsset.find(params[:video_asset_id])

    @video_clips = VideoClip.find(:all, :conditions=>{:video_asset_id => @video_asset.id})

    render :partial => 'clips'
  end

  




end
