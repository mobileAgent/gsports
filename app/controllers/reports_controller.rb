class ReportsController < BaseController

  skip_before_filter :gs_login_required, :only => [:detail]
  skip_before_filter :verify_authenticity_token, :only => [:clips, :player, :sync ]

  before_filter :except => [:show] do  |c| c.find_staff_scope(Permission::REPORT) end


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
    @browser_reject = request.user_agent =~ /msie 6/i


    @report = Report.find(params[:id])
    @details = @report.details() #ReportDetail.for_report(@report)
    #@detail = @details.first

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


  def sync
    @report = Report.find(params[:id])
    #@video_list = JSON.parse(params[:video_list].tr('\\', ''))
    list_param = params[:video_list].tr('\\', '').sub(/^"/,'').sub(/"$/,'')
    @video_list = JSON.parse(list_param)

    @report_details = []
    order = 1

    @video_list.each() do |video|
      if detail = ReportDetail.new(video)
        detail.report_id = @report.id
        detail.orderby = order += 1
        @report_details << detail
      end
    end

    Report.transaction {
      @report.details.each do |detail|
        detail.destroy
      end

      @report_details.each do |detail|
        detail.save
        #skipping errors
      end
    }

    dockeys = @report_details.collect(&:video).delete_if(){|v|v==nil}.collect(&:dockey)

    #vidavee = Vidavee.first
    #session_token = vidavee.login
    if dockey = @vidavee.new_playlist(session[:vidavee], "REPORT-PLAYLIST-#{@report.id}", dockeys, @report.dockey)
      @report.dockey = dockey
      @report.save
    end

    if params[:publish]
      render :partial => 'publish'
    else
      @detail = nil
      render :partial => 'player'
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
    @video_clips.delete_if() { |v|
      !current_user.has_access?(v)
    }

    render :partial => 'clips'
  end



  def player
    @report = Report.find(params[:id])

    @small_player= params[:small_player]

    if params[:video_type]
      @detail = ReportDetail.new({:video_type=>params[:video_type],:video_id=>params[:video_id]}) #.for_report(@report).for_item_type(params[:video_type], params[:video_id])
      #@detail.report = @report
      @detail.find_video()
    end    

    render :partial => 'player'
  end


  def detail
    debugger
    #@detail = ReportDetail.find(params[:id])
    @report = Report.find(params[:id])
    @detail = ReportDetail.new({:video_type=>params[:video_type],:video_id=>params[:video_id]})
    @detail.report = @report
    @small_player= params[:small_player]

    @dockey = @detail.video_id ? @detail.video.dockey : @report.dockey
    @dockey ||= 0

    options = {}
    options[:indent] ||= 2

    xml = options[:builder] ||= Builder::XmlMarkup.new(:indent => options[:indent])

    xml.instruct! unless options[:skip_instruct]
    out = xml.vars {
      xml.frameW(400)
      xml.frameH(330)
      xml.playerW(400)
      xml.playerH(330)
      xml.thumbW(0)
      xml.thumbH(0)
      xml.numColumnsOrRows(0)
      xml.numPerColumnOrRow(0)
      xml.dockeys(@dockey)
      #xml.homepageLink("#{APP_URL}/#{team_path(channel.team_id)}") if channel.team_id
      xml.homepageLink(APP_URL)
      xml.validationUrl(APP_URL)

      xml.autoPlay(true)

      xml.position('bottom')
    }

    respond_to do |format|
      format.xml {
        render :xml=>out #@channel.to_flash_xml
      }
    end

  end


  def show
    @report = Report.find(params[:id])

    unless current_user.has_access?(@report) #AccessGroup.allow_access?(current_user, @report)
      access_denied
      return
    end

    @details = @report.details() #ReportDetail.for_report(@report)
    #@detail = @details.first
    

  end


end
