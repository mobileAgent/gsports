class UsersController < BaseController

  if RAILS_ENV == 'production'
    ssl_required :billing, :submit_billing, :edit_billing, :update_billing
  end
  
  protect_from_forgery :only => [:create, :update, :destroy]
  before_filter :login_required, :only => [:edit, :edit_account, :update,
                                           :edit_billing, :update_billing,
                                           :welcome_photo, :welcome_about, :welcome_invite,
                                           :return_admin, :assume, :featured, 
                                           :toggle_featured, :edit_pro_details, :update_pro_details,
                                           :dashboard, :show, :index, :change_team_photo, :change_league_photo ]

  uses_tiny_mce(:options => AppConfig.gsdefault_mce_options.merge({:editor_selector => "rich_text_editor"}), 
                :only => [:new, :create, :update, :edit, :welcome_about])
  
  uses_tiny_mce(:options => AppConfig.narrow_mce_options.merge({:width => 330}),
                :only => [:show])

  def show
    @friend_count = @user.accepted_friendships.count
    @accepted_friendships = @user.accepted_friendships.find(:all, :limit => 5).collect{|f| f.friend }
    @pending_friendships_count = @user.pending_friendships.count()

    fav_cond = { :user_id => @user.id }
    @favorites = Favorite.find(:all, :limit=>5, :conditions=>fav_cond, :order => 'created_at DESC')
    @favorites_more = Favorite.count( :conditions=>fav_cond ) > 5

    @comments = @user.comments.find(:all, :limit => 10, :order => 'created_at DESC')
    @photo_comments = Comment.find_photo_comments_for(@user)

    @users_comments = Comment.find_comments_by_user(@user, :limit => 5)

    @recent_posts = @user.posts.find(:all, :limit => 2, :order => "published_at DESC")
    @clippings = @user.clippings.find(:all, :limit => 5)
    @photos = @user.photos.find(:all, :limit => 5)
    @comment = Comment.new(params[:comment])
    @clips = @user.video_clips.find(:all, :limit => 2, :order => "created_at DESC")
    @reels = @user.video_reels.find(:all, :limit => 2, :order => "created_at DESC")
    @profile_clips_and_reels = []
    while(@profile_clips_and_reels.size < 2 && (@clips.size + @reels.size > 0))
      @profile_clips_and_reels << @clips.shift if @clips.size > 0
      @profile_clips_and_reels << @reels.shift if @reels.size > 0
    end
    update_view_count(@user) unless current_user && current_user.eql?(@user)
  end

  # registration step 1
  def register
  end

  # registration step 2
  def new
    @requested_role = params[:role]

    @user = User.new( {:birthday => Date.parse((Time.now - 25.years).to_s) }.merge(params[:user] || {}) )
    @inviter_id = params[:id]
    @inviter_code = params[:code]
    #render :action => 'new', :layout => 'beta' and return if AppConfig.closed_beta_mode

  end

  def create
    @role = nil
    begin
      @requested_role = params[:role]
      return if @requested_role == Role[:admin] or @requested_role == Role[:moderator]
      @role = Role[@requested_role]
    rescue
    end

    @user = User.new(params[:user])
    @user.role = @role || Role[:member]
    @team = Team.find_or_create_by_name(params[:user][:team_name])

    # Assign any new teams coming in this way to the admin league
    if (@team.new_record?)
      @team.league_id = User.admin.first.league_id
      @team.save! 
    end
    
    @user.team_id = @team.id
    @user.login= "gs#{Time.now.to_i}#{rand(100)}" # We never use this
    @user.save!
    create_friendship_with_inviter(@user, params)

    redirect_to :action => 'billing', :userid => @user.id

  rescue ActiveRecord::RecordInvalid
    render :action => 'new'
  end

  # registration step 3
  def billing
    @user = User.find(params[:userid].to_i)
    logger.debug "USER session object(billing):" + @user.id.to_s
  end

  #
  # Capture payment
  #
  def submit_billing
    @user = User.find(params[:userid].to_i)
    billing_info = params[:billing]
    @credit_card = ActiveMerchant::Billing::CreditCard.new({
      :first_name => billing_info[:firstname],
      :last_name => billing_info[:lastname],
      :number => billing_info[:cardnumber],
      :month => billing_info["date(2i)"],
      :year => billing_info["date(1i)"],
      :verification_value => billing_info[:verificationnumber]
                                                           })
    
    if (!@credit_card.valid?)
      render :action => 'billing', :userid => @user.id
      return
    end

    gateway = ActiveMerchant::Billing::PayflowGateway.new({
      :login => Active_Merchant_payflow_gateway_username,
      :password => Active_Merchant_payflow_gateway_password,
      :partner => Active_Merchant_payflow_gateway_partner
                                                          })

    cost_for_gateway = (@user.role.plan.cost * 100).to_i
    @response = gateway.purchase(cost_for_gateway, @credit_card)
    
    if (@response.success?)
      logger.debug "Gatway response is success #{@response.inspect}"
      @user.make_member(Membership::CREDIT_CARD_BILLING_METHOD,nil,@response)
      @user.set_payment(@credit_card)
      @user.enabled = true
      @user.activated_at = Time.now
      @user.save!
      flash[:notice] = "Successfully charged $#{@user.role.plan.cost} to card #{@credit_card.display_number}"
      redirect_to signup_completed_user_path(@user)
    else
      logger.debug "Bad response from gateway #{@response.inspect}"
      flash.now[:warning] = @response.message
      render :action => 'billing', :userid => @user.id
    end
  end

  def change_team_photo
    @user = User.find(params[:id])
    if ((@user.team_staff? && current_user.id == @user.id) || current_user.admin?)
      @photo = Photo.find(params[:photo_id])
      h=@photo.height
      w=@photo.width
      if ((h==100 && w==100) || (h==60 && w=234))
        @team = @user.team
        @team.avatar= @photo
        if @team.save!
          flash[:notice] = "Your changes were saved."
        else
          flash[:notice] = "The change could not be saved: #{@team.errors}"
        end
      else
        flash[:notice] = "Team logo photos must be 100x100 or 234x60, this one is #{w}x#{h}"
      end
    end
    redirect_to user_photo_path(@user, @photo)
  end

  def change_league_photo
    @user = User.find(params[:id])
    if ((@user.league_staff? && current_user.id == @user.id) || current_user.admin?)
      @photo = Photo.find(params[:photo_id])
      h=@photo.height
      w=@photo.width
      if ((h==100 && w==100) || (h==60 && w=234))
        @league = League.find(@user.league_id)
        @league.avatar= @photo
        if @league.save!
          flash[:notice] = "Your changes were saved."
        else
          flash[:notice] = "The change could not be saved: #{@league.errors}"
        end
      else
        flash[:notice] = "League logo photos must be 100x100 or 234x60, this one is #{w}x#{h}"
      end
    end
    redirect_to user_photo_path(@user, @photo)
  end

  def auto_complete_for_user_team_name
    @teams = Team.find(:all, :conditions => ["LOWER(name) like ?", '%' + params[:user][:team_name].downcase + '%'], :order => "name ASC", :limit => 10)
    choices = "<%= content_tag(:ul, @teams.map { |t| content_tag(:li, h(t.name)) }) %>"    
    render :inline => choices
  end

  def update
    @user.attributes = params[:user]
    @avatar = Photo.new(params[:avatar])
    @avatar.user = @user
    if @avatar.save
      @user.avatar = @avatar
    end
    
    if @user.save!
      @user.track_activity(:updated_profile)
      
      @user.tag_with(params[:tag_list] || '')     
      flash[:notice] = "Your changes were saved."
      unless params[:welcome] 
        redirect_to user_path(@user)
      else
        redirect_to :action => "welcome_#{params[:welcome]}", :id => @user
      end
    end
  rescue ActiveRecord::RecordInvalid
    render :action => 'edit'
  end
  
  def update_account
    @user = current_user
    @user.attributes = params[:user]

    if @user.save!
      flash[:notice] = "Your changes were saved."
      redirect_to user_path(@user)
    end
  rescue ActiveRecord::RecordInvalid
    render :action => 'edit_account'
  end
  
  def dashboard
    @user = current_user
    @network_activity = @user.network_activity
    @recommended_posts = @user.recommended_posts
    # For league staff choose from among their teams
    team_id = @user.league_staff? ? @user.league.team_ids[rand(@user.league.team_ids.size)] : @user.team_id
    @featured_athletes_for_team = AthleteOfTheWeek.for_team(team_id)
    @featured_athletes_for_league = AthleteOfTheWeek.for_league(@user.league_id)
    @featured_game_for_team = GameOfTheWeek.for_team(team_id).first
    @featured_game_for_league = GameOfTheWeek.for_league(@user.league_id).first
  end

  def forgot_password  
    @user = User.find_by_email(params[:email])  
    return unless request.post?   
    if @user
      if @user.reset_password
        UserNotifier.deliver_reset_password(@user)
        @user.save
        flash[:info] = "Your password has been reset and emailed to you."
        redirect_to url_for({:controller => 'base', :action => 'site_index'}) 
      end
    else
      flash[:error] = "Sorry. We don't recognize that email address."
    end 
  end

  def edit_billing
    id = params[:id] || current_user.id
    @user = User.find(id)
    unless (@user.id == current_user.id || current_user.admin?)
      @user = nil
      flash[:notice] = "Insufficient permission to edit"
      redirect_to dashboard_user_path(current_user) and return
    end
    @memberships = @user.memberships
    if @memberships && @memberships.size > 0
      @credit_card = @memberships[0].credit_card
    else
      @credit_card = CreditCard.new
    end
  end

  def update_billing
    id = params[:id] || current_user.id
    @user = User.find(id)
    @memberships = @user.memberships
    if (@user.id == current_user.id || current_user.admin?)
      # Have to test with an AM::B:CC in order to validate
      cc=params[:credit_card]
      logger.debug "CC params inbound are #{cc.inspect}"
      @credit_card = ActiveMerchant::Billing::CreditCard.new({
        :first_name => cc[:first_name],
        :last_name => cc[:last_name],
        :number => cc[:number],
        :month => cc["expiration_date(2i)"],
        :year => cc["expiration_date(1i)"],
        :verification_value => cc[:verification_value]})

      
      if (!@credit_card.valid?)
        # Have to have one of ours on the form
        @am_credit_card = @credit_card
        if @memberships && @memberships.size > 0
          @credit_card = @memberships[0].credit_card
        else
          @credit_card = CreditCard.new(params[:credit_card])
        end

        logger.debug "Failed validation on #{@am_credit_card.errors}, new CC setup as #{@credit_card.inspect}"
        render :action => 'edit_billing' and return
      end

      unless @memberships && @memberships.size > 0
        @user.make_member(Membership::CREDIT_CARD_BILLING_METHOD,nil,'pending')
      end
      @user.set_payment(@credit_card)
      
      if @user.save!
        flash[:notice] = "Billing updates have been saved"
        redirect_to edit_account_user_path(@user) and return
      end
    else
      @user = nil
      flash[:notice] = "Insufficient permission to udpate"
      redirect_to dashboard_user_path(@user) and return
    end
  end
  
end
