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
    unless current_user.admin? || current_user.id == @user.id || @user.profile_public
      render :action => 'private'
    end
    
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
      @requested_role = params[:role].to_i
      return if (Role[:admin].id  == @requested_role or Role[:moderator].id == @requested_role)
      @role = Role[@requested_role]
    rescue
      logger.debug "Could not set role from #{params[:role]}"
      @role = Role[:member]
    end

    @user = User.new(params[:user])
    @user.role_id = @role.id
    logger.debug "Setting role for #{@user.email} to #{@user.role_id}"

    if @user.role_id == Role[:league].id
      # Special handling for league role coming in
      @league = League.find_or_create_by_name(params[:user][:league_name])
      @league.save! if @league.new_record?
      @user.league_id = @league.id
      @user.team_id = User.admin.first.team_id
    else
      # Handling for Team and member roles coming in
      @team = Team.find_or_create_by_name(params[:user][:team_name])
      if (@team.new_record?)
        @team.league_id = User.admin.first.league_id
        @team.save! 
      end
      @user.team_id = @team.id
      @user.league_id = @team.league_id
    end
    
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
    @billing_address = Address.new(params[:billing_address])
    @credit_card = ActiveMerchant::Billing::CreditCard.new(params[:credit_card])
    @credit_card.first_name = @user.firstname if (! @credit_card.first_name) 
    @credit_card.last_name = @user.lastname if (! @credit_card.last_name) 
    logger.debug "USER session object(billing):" + @user.id.to_s
  end

  #
  # Capture payment
  #
  def submit_billing
    @user = User.find(params[:userid].to_i)
    cc = params[:credit_card]
    @credit_card = ActiveMerchant::Billing::CreditCard.new({
      :first_name => cc[:first_name],
      :last_name => cc[:last_name],
      :number => cc[:number],
      :month => cc[:month],
      :year => cc[:year],
      :verification_value => cc[:verification_value]})
    @billing_address = params[:skip_billing_address] ? nil : Address.new(params[:billing_address])
    
    if (!@credit_card.valid?)
      @billing_address ||= Address.new
      render :action => 'billing', :userid => @user.id
      return
    end

    gateway = ActiveMerchant::Billing::PayflowGateway.new({
      :login => Active_Merchant_payflow_gateway_username,
      :password => Active_Merchant_payflow_gateway_password
                                                          })

    cost_for_gateway = (@user.role.plan.cost * 100).to_i
    @response = gateway.purchase(cost_for_gateway, @credit_card)
    
    logger.debug "Response from gateway #{@response.inspect} for #{@user.full_name} at #{cost_for_gateway}"
    
    if (@response.success?)
      logger.debug "Gatway response is success #{@response.inspect}"
      @user.make_member(Membership::CREDIT_CARD_BILLING_METHOD,@billing_address,@response)
      @user.set_payment(@credit_card)
      @user.enabled = true
      @user.activated_at = Time.now
      @user.save!
      self.current_user = @user # Log them in right now!
      UserNotifier.deliver_welcome(@user)
      redirect_to signup_completed_user_path(@user)
    else
      @billing_address ||= Address.new
      flash.now[:warning] = "Sorry, we are having technical difficulties contacting our payment gateway. Try again in a few minutes."
      @billing_gateway_error = "#{flash.now[:warning]} (#{@response.message})"
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
  
  def auto_complete_for_user_league_name
    @leagues = League.find(:all, :conditions => ["LOWER(name) like ?", '%' + params[:user][:league_name].downcase + '%'], :order => "name ASC", :limit => 10)
    choices = "<%= content_tag(:ul, @leagues.map { |l| content_tag(:li, h(l.name)) }) %>"    
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
      @billing_address = @memberships[0].address || Address.new
    else
      @credit_card = CreditCard.new
      @billing_address = Address.new
    end
  end

  def update_billing
    id = params[:id] || current_user.id
    @user = User.find(id)
    unless (@user.id == current_user.id || current_user.admin?)
      @user = nil
      flash[:notice] = "Insufficient permission to udpate"
      redirect_to dashboard_user_path(@user) and return
    end
    
    # Have to test with an AM::B:CC in order to validate
    cc=params[:credit_card]
    logger.debug "CC params inbound are #{cc.inspect}"
    @merchant_credit_card = ActiveMerchant::Billing::CreditCard.new({
                             :first_name => cc[:first_name],
                             :last_name => cc[:last_name],
                             :number => cc[:number],
                             :month => cc["expiration_date(2i)"],
                             :year => cc["expiration_date(1i)"],
                             :verification_value => cc[:verification_value]})

    # Have to have one of ours on the form and db
    @memberships = @user.memberships
    if @memberships && @memberships.size > 0
      @credit_card = @memberships[0].credit_card
      @billing_address = @memberships[0].address || Address.new
    end

    @billing_address = params[:skip_billing_address] ? nil : Address.new(params[:billing_address])
    @credit_card ||= CreditCard.new # Can't create card from params due to date issues
    @credit_card.attributes = ({:first_name => cc[:first_name],
                                 :last_name => cc[:last_name],
                                 :number => cc[:number],
                                 :month => cc["expiration_date(2i)"],
                                 :year => cc["expiration_date(1i)"],
                                 :verification_value => cc[:verification_value]})

    
    if (!@merchant_credit_card.valid?)
      render :action => 'edit_billing' and return
    end
    
    unless @memberships && @memberships.size > 0
      @user.make_member(Membership::CREDIT_CARD_BILLING_METHOD,@billing_address,nil)
    end
    
    @user.memberships[0].credit_card = @credit_card
    @user.memberships[0].address = @billing_address if @billing_address
    
    if @user.save!
      flash[:notice] = "Billing updates have been saved"
      if current_user.admin?
        redirect_to url_for({:controller => 'users', :action => 'edit_account', :id => @user}) and return
      else
        redirect_to edit_account_user_path(@user) and return
      end
    end
  end
  
end
