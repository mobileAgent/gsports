class UsersController < BaseController

  if RAILS_ENV == 'production' || RAILS_ENV == 'qa'
    ssl_required :billing, :submit_billing, :edit_billing, :update_billing
  end
  
  protect_from_forgery :only => [:create, :update, :destroy]
  skip_before_filter :gs_login_required, :only => [:signup, :register, :new, :create, :billing, :submit_billing, :auto_complete_for_user_team_name, :auto_complete_for_team_league_name, :forgot_password, :registration_fill_team]
  skip_before_filter :billing_required, :only => [:renew, :billing, :edit_billing, :submit_billing, :update_billing, :auto_complete_for_user_league_name]
  before_filter :admin_required, :only => [:assume, :destroy, :featured, :toggle_featured, :toggle_moderator, :disable]
  before_filter :find_user, :only => [:edit, :edit_pro_details, :show, :update, :destroy, :statistics, :disable ]
  
  uses_tiny_mce(:options => AppConfig.gsdefault_mce_options.merge({:editor_selector => "rich_text_editor"}), 
                :only => [:new, :create, :update, :edit, :welcome_about])
  
  uses_tiny_mce(:options => AppConfig.narrow_mce_options.merge({:width => 300}),
                :only => [:show])
  
  def show
    # The current user can see @user's profile only if
    # they are the admin, themselves, the profile is public
    # or they are a friend of @user
    unless (current_user.admin? || current_user.id == @user.id || @user.profile_public || @user.accepted_friendships.collect(&:friend_id).member?(current_user.id))
      render :action => 'private'
    end
    
    @friend_count = @user.accepted_friendships.count
    @accepted_friendships = @user.accepted_friendships.find(:all, :limit => 5, :include => [:friend]).collect{|f| f.friend }
    @pending_friendships_count = @user.pending_friendships.count()

    fav_cond = { :user_id => @user.id }
    @favorites = Favorite.find(:all, :limit=>5, :conditions=>fav_cond, :order => 'created_at DESC')
    @favorites_more = Favorite.count( :conditions=>fav_cond ) > 5

    @comments = @user.comments.find(:all, :limit => 10, :order => 'created_at DESC')
    @photo_comments = Comment.find_photo_comments_for(@user)

    # @users_comments = Comment.find_comments_by_user(@user, :limit => 5)

    @recent_posts = @user.posts.find(:all, :limit => 2, :order => "published_at DESC")
    # @clippings = @user.clippings.find(:all, :limit => 5)
    @photos = @user.photos.find(:all, :limit => 5)
    @comment = Comment.new(params[:comment])
    @published_post_count = Post.count(:all, :conditions => ["user_id = ? and published_as = ?", @user.id, 'live'])
    @clips = @user.video_clips.find(:all, :limit => 2, :order => "created_at DESC")
    @reels = @user.video_reels.find(:all, :limit => 2, :order => "created_at DESC")
    @profile_clips_and_reels = []
    while(@profile_clips_and_reels.size < 2 && (@clips.size + @reels.size > 0))
      @profile_clips_and_reels << @clips.shift if @clips.size > 0
      @profile_clips_and_reels << @reels.shift if @reels.size > 0
    end
    update_view_count(@user) unless current_user && current_user.eql?(@user)
  end

  # registration step 0, coming from an invitation link
  # need to grab the inviter stuff while it is hot
  def signup
    session[:inviter_id] = params[:inviter_id]
    session[:inviter_code] = params[:inviter_code]
    redirect_to '/info/about'
  end

  # registration step 1
  def register
    @inviter_id = session[:inviter_id] || params[:inviter_id]
    @inviter_code = session[:inviter_code] || params[:inviter_code]
  end

  # registration step 2
  def new
    @requested_role = (params[:role] || Role[:member].id).to_i
    
    case @requested_role
    when Role[:team].id
      @team = Team.new
    when Role[:league].id
      @league = League.new
    end
    
    default_options = {
      :birthday => Date.parse((Time.now - 25.years).to_s) ,
      :country => Country.find(207)
    }
    
    @user = User.new( default_options.merge(params[:user] || {}) )
    @inviter_id = params[:id]
    @inviter_code = params[:code]
    
    session[:promotion] = nil
    
    #render :action => 'new', :layout => 'beta' and return if AppConfig.closed_beta_mode
  end

  # Fills in the registration team block when registering as team admin
  def registration_fill_team
    @team = Team.find_by_name(params[:name])
    respond_to do |format|
      format.xml  { render :xml => @team }
      format.js { render :action => "registration_fill_team" } # => registration_fill_team.rjs
    end
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

    case @role.id
    when Role[:team].id
      @team = Team.find_or_create_by_name(params[:user][:team_name])
      @team.attributes = params[:team]
      if (@team.league.nil?)
        @team.league = User.admin.first.league
        logger.debug "Setting team league to admin value"
      end
      @team.save! 
      @user.team = @team
      if (@team.league)
        @user.league = @team.league
      end
      
    when Role[:league].id
      @league = League.find_or_create_by_name(params[:user][:league_name])
      @league.attributes = params[:league]
      @league.save!
      @user.league = @league
      @user.team = User.admin.first.team
      
    when Role[:scout].id
      @user.team = User.admin.first.team
      @user.league = User.admin.first.league
      
    else
        # Handling for member roles coming in
        @team = Team.find_or_create_by_name(params[:user][:team_name])
        if (@team.new_record?)
          @team.league_id = User.admin.first.league_id
          @team.save! 
        end
        @user.team_id = @team.id
        @user.league_id = @team.league_id
    end   
    
    # Lookup up promo code if provided
    unless params[:promo_code].blank?
      logger.debug "Looking up promo code #{params[:promo_code]}"
      @promotion = Promotion.find_by_promo_code(params[:promo_code])

      if @promotion == nil || !@promotion.enabled? ||
            (@promotion.subscription_plan_id != nil && 
             @role.plan != nil && @role.plan.id != @promotion.subscription_plan_id)

        if @promotion == nil
          logger.debug "Promotion not found for #{params[:promo_code]}."
        elsif !@promotion.enabled?
          logger.debug "Promotion has been disabled for #{params[:promo_code]}."
        else
          logger.debug "Promotion not valid for role: #{@role.plan.id} != #{@promotion.subscription_plan_id}"
        end
        flash.now[:error] = "Sorry, the promotion code you entered is invalid: #{params[:promo_code]}."
        @promotion = nil
        render :action => 'new', :role => @role.id and return false
      else
        logger.debug  "Promotion: #{@promotion.promo_code}: #{@promotion.name}"
        flash[:notice] = "The promotion #{@promotion.name} has been applied!"
        session[:promotion] = @promotion
      end
    end
    
    @user.login= "gs#{Time.now.to_i}#{rand(1000)}" # We never use this
    @user.save!
    create_friendship_with_inviter(@user, params)
    
    redirect_to :action => 'billing', :userid => @user.id

  rescue ActiveRecord::RecordInvalid => e
    render :action => 'new'
  end  

  # registration step 3
  def billing
    id = params[:userid] || params[:id] || current_user.id
    @user = User.find(id)

    @promotion = session[:promotion]
    
    # check for promotional pricing
    if @promotion != nil && @promotion.cost != nil
      @cost = @promotion.cost
      logger.debug "Using promotional pricing: #{@cost}"
    else
      @cost = @user.role.plan.cost
    end
    
    # only initialize billing information if we have a cost > 0
    if @cost > 0
      @billing_address = Address.new(params[:billing_address])
      @credit_card = ActiveMerchant::Billing::CreditCard.new(params[:credit_card])
      @offer_PO = @user.team_staff? || @user.league_staff?
    
      #@credit_card.first_name = @user.firstname if (! @credit_card.first_name) 
      #@credit_card.last_name = @user.lastname if (! @credit_card.last_name)
    end

    logger.debug "USER session object(billing):" + @user.id.to_s
  end

  #
  # Capture payment
  #
  def submit_billing
    id = params[:userid] || params[:id] || current_user.id
    @user = User.find(id)
    
    @promotion = session[:promotion]
    
    if @promotion != nil && @promotion.cost != nil
      @cost = @promotion.cost
      logger.debug "Using promotional pricing: #{@cost}"      
    else
      @cost = @user.role.plan.cost
    end
    
    if @cost == 0
      @user.make_member(Membership::FREE_BILLING_METHOD,0,nil,nil,nil,@promotion)
    else
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
  
      gateway = ActiveMerchant::Billing::PayflowGateway.new(
        :login => Active_Merchant_payflow_gateway_username,
        :password => Active_Merchant_payflow_gateway_password,
        :partner => Active_Merchant_payflow_gateway_partner)
  
      cost_for_gateway = (@cost * 100).to_i
      @response = gateway.purchase(cost_for_gateway, @credit_card)
      
      logger.debug "Response from gateway #{@response.inspect} for #{@user.full_name} at #{cost_for_gateway}"
      
      if (@response.success?)
        logger.debug "Gatway response is success #{@response.inspect}"
        credit_card_for_db = CreditCard.from_active_merchant_cc(@credit_card)
        credit_card_for_db.user = @user
        credit_card_for_db.save!
        @user.make_member(Membership::CREDIT_CARD_BILLING_METHOD,@cost,@billing_address,credit_card_for_db,@response,@promotion)
      else
        @billing_address ||= Address.new
        flash.now[:error] = "Sorry, we are having technical difficulties contacting our payment gateway. Try again in a few minutes."
        @billing_gateway_error = "#{flash.now[:warning]} (#{@response.message})"
        render :action => 'billing', :userid => @user.id
        return false;
      end      
    end
    
    @user.enabled = true
    @user.activated_at = Time.now
    @user.save!
    self.current_user = @user # Log them in right now!
    UserNotifier.deliver_welcome(@user)
    redirect_to signup_completed_user_path(@user)
  end
  
  def signup_completed
    if session[:promotion]
      logger.debug "Clearing out promotion from the session..."
      session[:promotion] = nil
    end
  end
  
  def renew
    # TODO: need a renewal screen here
    redirect_to :action => 'billing', :userid => current_user.id
  end
  
  def disable
    unless @user.admin?
      @user.enabled=false
      flash[:notice] = "The user account has been disabled."
    else
      flash[:error] = "You can't disable that user."
    end
    respond_to do |format|
      format.html { redirect_to users_url }
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
    
    @team = Team.find(:first, :conditions=>{:name => params[:user][:team_name]})
    @user.team = @team if @team
    
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
    @recent_uploads = Dashboard.recent_uploads(@user)
    @popular_videos = Dashboard.popular_videos(@user)
    @network_recent = Dashboard.network_recent(@user)
    @network_favorites = Dashboard.network_favorites(@user)
    
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
    @membership = @user.membership
    if !@membership.nil?
      # ActiveMerchant::Billing::CreditCard vs CreditCard confusion....
      @credit_card = @membership.credit_card
      @billing_address = @membership.address || Address.new
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
      flash[:notice] = "Insufficient permission to update"
      redirect_to dashboard_user_path(@user) and return
    end

    @billing_address = params[:skip_billing_address] ? nil : Address.new(params[:billing_address])
    if !@billing_address.nil? && params[:billing_address][:id]
      logger.debug "Preserving address ID: #{params[:billing_address][:id]}"
      @billing_address.id = params[:billing_address][:id]
    end
    
    # Have to have one of ours on the form and db
    @membership = @user.membership
    if !@membership.nil?
      @existing_credit_card = @membership.credit_card
      @billing_address ||= @membership.address || Address.new
      @cost = @membership.cost
    end
    @existing_credit_card ||= CreditCard.new # Can't create card from params due to date issues
    
    # Have to test with an AM::B:CC in order to validate
    cc=params[:credit_card]

    number = cc[:number]
    if number.index("***")
      number = @existing_credit_card.number
    end
    ccv = cc[:verification_value]    
    if ccv.index("***")
      ccv = @existing_credit_card.verification_value
    end

    @am_credit_card = ActiveMerchant::Billing::CreditCard.new({
                             :first_name => cc[:first_name],
                             :last_name => cc[:last_name],
                             :number => number,
                             :month => cc[:month],
                             :year => cc[:year],
                             :verification_value => ccv})


    # Confusing CreditCard objects, app and ActiveMerchant::Billing::CreditCard
    @credit_card = CreditCard.from_active_merchant_cc(@am_credit_card)
    @credit_card.user = @user

    if (!@am_credit_card.valid?)
      render :action => 'edit_billing' and return
    end

    @membership = @user.membership

    # This will save the credit card record if the CC has changed
    if @existing_credit_card == nil || !@credit_card.equals?(@existing_credit_card)
      logger.debug "Saving changes to credit card..."
      @credit_card.save!
      
      if !@membership.nil?
        @membership.credit_card = @credit_card
      end
    end

    if !@membership.nil?
      logger.debug "Saving membership(s)..."
      @membership.address = @billing_address
    end

    # We may need to execute a billing transaction right now
    if @user.billing_needed?      
      logger.info "Need to execute a billing transaction for this account"
      
      gateway = ActiveMerchant::Billing::PayflowGateway.new(
          :login => Active_Merchant_payflow_gateway_username,
          :password => Active_Merchant_payflow_gateway_password,
          :partner => Active_Merchant_payflow_gateway_partner)
     
      # cost fall back to plan amount if nil
      if @cost == nil
        @cost = @user.role.plan.cost;
      end
      
      # no decimals posted to gateway
      cost_for_gateway = (@cost * 100).to_i
      
      # make the purchase
      @response = gateway.purchase(cost_for_gateway, @am_credit_card)      
      logger.debug "Response from gateway #{@response.inspect} for #{cost_for_gateway}"
     
      if (@response.success?)
        # Not sure this makes any sense... what are we billing for if no memberships?
        if @membership.nil
          @user.make_member(Membership::CREDIT_CARD_BILLING_METHOD,@cost,@billing_address,@credit_card,nil)
          @membership = @user.membership
        end
        
        @membership.address = @billing_address if @billing_address
        @membership.credit_card = @credit_card

        history = MembershipBillingHistory.new
        pf = @response.params
        history.authorization_reference_number = "#{pf['pn_ref']}/#{pf['auth_code']}"
        history.payment_method = @membership.billing_method
        history.credit_card = @membership.credit_card
        @membership.membership_billing_histories << history
      else
        flash.now[:error] = "Sorry, we are having technical difficulties contacting our payment gateway. Try again in a few minutes."
        @billing_gateway_error = "#{flash.now[:warning]} (#{@response.message})"
        render :action => 'edit_billing', :userid => @user.id
        return false;
      end    
    end
    # end of billing execution

    if @user.save!
      if current_user.admin?
        redirect_to url_for({:controller => 'users', :action => 'edit_account', :id => @user}) and return
      else
        redirect_to edit_account_user_path(@user) and return
      end
    end
  end

  def auto_complete_for_team_league_name
    @leagues = League.find(:all, :conditions => ["LOWER(name) like ?", params[:team][:league_name].downcase + '%' ], :order => "name ASC", :limit => 10 )
    choices = "<%= content_tag(:ul, @leagues.map { |l| content_tag(:li, h(l.name)) }) %>"    
    render :inline => choices
  end


end
