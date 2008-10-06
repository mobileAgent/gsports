class UsersController < BaseController

  if RAILS_ENV == 'production' || RAILS_ENV == 'qa'
    ssl_required :billing, :submit_billing, :edit_billing, :update_billing
  end
  
  protect_from_forgery :only => [:create, :update, :destroy]
  skip_before_filter :gs_login_required, :only => [:signup, :register, :new, :create, :billing, :submit_billing, :forgot_password, 
                                                   :registration_fill_team, :registration_fill_teams_by_state,
                                                   :registration_fill_league, :registration_fill_leagues_by_state,
                                                   :auto_complete_for_user_team_name, :auto_complete_for_team_league_name]
  
  skip_before_filter :billing_required, :only => [:billing, :edit_billing, :submit_billing, :update_billing, 
                                                  :account_expired, :membership_canceled, :renew, :cancel_membership, 
                                                  :auto_complete_for_user_league_name]
  
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
    
    @membership = @user.current_membership
    
    # Canceled memberships are hidden to all but admin users
    if @membership && @membership.canceled? && !current_user.admin?
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
    when Role[:league].id
      begin
        @league = League.find(params[:league][:id])
        logger.debug "Existing league found: #{@league.id}: #{@league.name}"

        @league_admin = @league.admin_user
        if @league_admin
           message = "#{@league.name} has already been registered by #{@league_admin.full_name}"
           logger.error message
           @league.errors.add('',message)
           raise Exception.new message
        end

      rescue ActiveRecord::RecordNotFound        
        # Should we try to find duplicates here or not?
        #@league = League.find(:first, :conditions => { :name => p_league[:name].to_i, :state_id => p_league[:state_id].to_i })
        
        @league = League.new params[:league]
        logger.debug "New league #{@league.name}"
        @league.save!
      end
      @user.league = @league
      @user.team = User.admin.first.team
      
    when Role[:scout].id
      @user.team = User.admin.first.team
      @user.league = User.admin.first.league
      
    when Role[:team].id 
      begin
        @team = Team.find(params[:team][:id])
        logger.debug "Existing team found: #{@team.id}: #{@team.name}"
        @team_admin = @team.admin_user
        if @team_admin
           message = "#{@team.name} has already been registered by #{@team_admin.full_name}"
           logger.error message
           @team.errors.add('',message)
           raise Exception.new message
        end
        logger.debug "Updating attributes for team from form"
        @team.update_attributes! params[:team]
      rescue ActiveRecord::RecordNotFound        
        @team = Team.new params[:team]
        logger.debug "New team: #{@team.name}"
        if @team.league.nil?
          @team.league = User.admin.first.league
          logger.debug "Setting team league to admin value"
        end
        
        logger.debug "Saving new team"
        @team.save! 
      end

      @user.team = @team
      if (@team.league)
        @user.league = @team.league
      end
    else # when Role[:member].id
      begin
        @team = Team.find(params[:team][:id])
      rescue ActiveRecord::RecordNotFound        
        @team = Team.new params[:team]
        logger.debug "New team: #{@team.name}"
        if @team.league.nil?
          @team.league = User.admin.first.league
          logger.debug "Setting team league to admin value"
        end
        
        logger.debug "Saving new team"
        @team.save! 
      end

      @user.team = @team
      if (@team.league)
        @user.league = @team.league
      end

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
        @promotion.errors.add('', "Sorry, the promotion code you entered is invalid: #{params[:promo_code]}.")
        raise Exception.new, "Invalid promotion code"
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

  rescue Exception
  
    # Need to fill the teams/leagues drop down before returning to the screen
    if @role.id == Role[:league].id
      if @league && @league.state_id
        @leagues = _get_leagues_by_state @league.state_id
      end
    else
      if @team && @team.state_id
        @teams = _get_teams_by_state @team.state_id
      end
    end

    render :action => 'new'
  end  

  # registration step 3
  def billing
    id = params[:userid] || params[:id] || current_user.id
    @user = User.find(id)

    @promotion = session[:promotion]
    
    # check for promotional pricing
    if (@promotion && !@promotion.cost.nil?)
      @cost = @promotion.cost
      logger.debug "Using promotional pricing: #{@cost}"
    else
      @cost = @user.role.plan.cost
    end
    

    # need to provide credit card even if price == 0
    @billing_address = Address.new(params[:billing_address])
    @credit_card = ActiveMerchant::Billing::CreditCard.new(params[:credit_card])
    @offer_PO = @user.team_staff? || @user.league_staff?
  
    #@credit_card.first_name = @user.firstname if (! @credit_card.first_name) 
    #@credit_card.last_name = @user.lastname if (! @credit_card.last_name)

    logger.debug "USER session object(billing):" + @user.id.to_s
  end

  #
  # Capture payment
  #
  def submit_billing
    id = params[:userid] || params[:id] || current_user.id
    @user = User.find(id)
    
    @promotion = session[:promotion]
    
    if (@promotion && !@promotion.cost.nil?)
      @cost = @promotion.cost
      logger.debug "Using promotional pricing: #{@cost}"      
    else
      @cost = @user.role.plan.cost
    end
    
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

    # if the cost is 0, we need to make a $1, and then void it for verification 
    cost_for_gateway = @cost == 0 ? 1.to_i : (@cost * 100).to_i
    @response = gateway.purchase(cost_for_gateway, @credit_card)

    logger.debug "Response from gateway #{@response.inspect} for #{@user.full_name} at #{cost_for_gateway}"
    
    if (@response.success?)
      logger.debug "Gatway response is success #{@response.inspect}"

      # Void the $1.00 transaction post haste!
      if @cost == 0
        void_transaction(@response)
      end
      
      credit_card_for_db = CreditCard.from_active_merchant_cc(@credit_card)
      credit_card_for_db.user = @user
      credit_card_for_db.save!

      @user.make_member_by_credit_card(@cost,@billing_address,credit_card_for_db,@response,@promotion)

    else
      @billing_address ||= Address.new
      
      if @response.message.nil? || @reponse.message.blank?
        flash.now[:error] = "Sorry, we are having technical difficulties contacting our payment gateway. Try again in a few minutes."
      else
        @billing_gateway_error = "#{flash.now[:warning]} (#{@response.message})"
      end
      
      render :action => 'billing', :userid => @user.id
      return false;
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
  
  def account_expired
    session[:promotion] = nil
    @user = current_user
    @membership = @user.current_membership
  end
  
  def renew    
    if current_user && current_user.admin? && params[:id]
      @user = User.find(params[:id]) || current_user
    else
      @user = current_user
    end
    
    # Get the user's best/most-recent membership
    @membership = @user.current_membership;
    
    # Pre-fill from the most recent membership, if available
    @billing_address = @membership ? @membership.address : Address.new;
    
    # Pre-fill credit card from the most recent
    @credit_card = @membership && @membership.credit_card ? 
        @membership.credit_card : ActiveMerchant::Billing::CreditCard.new
        
    @offer_PO = @user.team_staff? || @user.league_staff?    
    
    # Lookup up promo code if provided
    unless params[:promo_code].blank?
      logger.debug "Looking up promo code #{params[:promo_code]}"
      @promotion = Promotion.find_by_promo_code(params[:promo_code])

      if @promotion == nil || !@promotion.enabled? ||
            (@promotion.subscription_plan_id != nil && 
             @user.role.plan != nil && @user.role.plan.id != @promotion.subscription_plan_id)

        if @promotion == nil
          logger.debug "Promotion not found for #{params[:promo_code]}."
        elsif !@promotion.enabled?
          logger.debug "Promotion has been disabled for #{params[:promo_code]}."
        else
          logger.debug "Promotion not valid for role: #{@role.plan.id} != #{@promotion.subscription_plan_id}"
        end
        
        flash.now[:error] = "Sorry, the promotion code you entered is invalid: #{params[:promo_code]}."
        @promotion = nil
        render :action => 'account_expired' and return false

      elsif !@promotion.reusable? && 
                @user.memberships && 
                !@user.memberships.find_all{ |mem| mem.promotion_id == @promotion.id }.empty?

        logger.debug "Promotion is not reusable: #{@promotion.promo_code}:"
        flash.now[:error] = "Sorry, the promotion code you entered may not be used more than once: #{params[:promo_code]}."
        @promotion = nil
        render :action => 'account_expired' and return false

      else
        logger.debug  "Promotion: #{@promotion.promo_code}: #{@promotion.name}"
        flash[:notice] = "The promotion #{@promotion.name} has been applied!"
        session[:promotion] = @promotion
      end
    end

    @cost = (@promotion && !@promotion.cost.nil?) ? @promotion.cost : @user.role.plan.cost
    render :action => 'billing', :userid => @user.id
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
    @membership = @user.current_membership
    if !@membership.nil?
      # ActiveMerchant::Billing::CreditCard vs CreditCard confusion....
      @credit_card = @membership.credit_card || @user.credit_card || CreditCard.new
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
    @membership = @user.current_membership
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

    @membership = @user.current_membership

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
        if @membership.nil?
          @user.make_member_by_credit_card(@cost,@billing_address,@credit_card,@response)
          @membership = @user.current_membership
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
  
  def cancel_membership
    if current_user && current_user.admin? && params[:id]
      @user = User.find(params[:id]) || current_user
    else
      @user = current_user
    end
    
    @membership = @user.current_membership
    if @membership && !@membership.canceled?
      logger.info "Requesting membership cancellation for #{@user.id}: #{@user.email}"
      @cancellation = MembershipCancellation.new
      @cancellation.membership = @membership
    else
      logger.warn "Cannot cancel membership for #{@user.id}: #{@user.email}"
      flash[:warn] = "Membership is already cancelled"
      redirect_to user_path(@user)
    end    
  end
  
  def submit_cancellation
    if current_user && current_user.admin?
      id = params[:id] || params[:user][:id]
      @user = User.find(id) || current_user
    else
      @user = current_user
    end
    
    @membership = @user.current_membership
    if @membership && !@membership.canceled?
      logger.info "Cancelling membership for #{@user.id}: #{@user.email}"
      
      cancellation = MembershipCancellation.new params[:cancellation]
      cancellation.membership = @membership
      
      @membership.status = Membership::STATUS_CANCELED
      @membership.membership_cancellation = cancellation
      @membership.save!
      
      flash[:notice] = "Membership has been cancelled"      
      if @user.id == current_user.id
        redirect_to :action => 'membership_canceled', :id => @user.id
      else
        redirect_to user_path(@user)
      end
    else
      logger.warn "Cannot cancel membership for #{@user.id}: #{@user.email}"
      flash[:warn] = "Membership is already cancelled"      
      redirect_to user_path(@user)
    end        
  end
  
  def membership_canceled
    @user = current_user
  end  

  # Fills in the registration team block when registering as team admin
  def registration_fill_team
    if params[:team_id] && !params[:team_id].blank?
      @team = Team.find_by_id(params[:team_id])
    elsif params[:name] && !params[:name].blank?
      @team = Team.find_by_name(params[:name])  
    end
    
    # Preserve state_id if provided
    if @team.nil?
      if params[:state_id]
        @team = Team.new :state_id => params[:state_id]
      end
    end
   
    respond_to do |format|
      format.xml  { render :xml => @team }
      format.js { render :action => "registration_fill_team" } # => registration_fill_team.rjs
    end
  end
  
    # Fills in the registration team block when registering as team admin
  def registration_fill_teams_by_state
    @teams = _get_teams_by_state params[:state_id]

    respond_to do |format|
      format.xml  { render :xml => @teams }
      format.js { render :action => "registration_fill_team" } # => registration_fill_team.rjs
    end
  end

  # Fills in the registration league block when registering as league admin
  def registration_fill_league
    if params[:league_id] && !params[:league_id].blank?
      @league = League.find_by_id(params[:league_id])
    elsif params[:name] && !params[:name].blank?
      @league = League.find_by_name(params[:name])  
    end
    
    # Preserve state_id if provided
    if @league.nil?
      if params[:state_id]
        @league = League.new :state_id => params[:state_id]
      end
    end
    
    respond_to do |format|
      format.xml  { render :xml => @league }
      format.js { render :action => "registration_fill_league" } # => registration_fill_league.rjs
    end
  end
  
    # Fills in the registration league block when registering as league admin
  def registration_fill_leagues_by_state
    @leagues = _get_leagues_by_state params[:state_id]
    
    respond_to do |format|
      format.xml  { render :xml => @leagues }
      format.js { render :action => "registration_fill_league" } # => registration_fill_league.rjs
    end
  end

  

  protected
  
  def _get_teams_by_state(state_id)
    if state_id && !state_id.blank?
      teams = Team.find_all_by_state_id(state_id)
      teams.delete(User.admin.first.team)
      teams.sort! {|x,y| x.name.upcase <=> y.name.upcase }
      teams << (Team.new :name => "-- My school/club is not listed --", :state_id => state_id)
    end      
  end
  
  def _get_leagues_by_state(state_id)
    if state_id && !state_id.blank?
      leagues = League.find_all_by_state_id(state_id)
      leagues.delete(User.admin.first.league)
      leagues.sort! {|x,y| x.name.upcase <=> y.name.upcase }
      leagues << (Team.new :name => "-- My league is not listed --", :state_id => state_id)
    end      
  end
  
  def void_transaction(payment_response)
    return false if payment_response.nil?
    
    # void the $1.00 payment
    authorization = payment_response.params['pn_ref']        
     
    logger.debug ("*** VOIDING Temporary $1.00 TX: " + authorization)
    
    gateway = ActiveMerchant::Billing::PayflowGateway.new(
      :login => Active_Merchant_payflow_gateway_username,
      :password => Active_Merchant_payflow_gateway_password,
      :partner => Active_Merchant_payflow_gateway_partner)

    void_response = gateway.void(authorization)
    if (!void_response.success?)
      logger.error ("**** FAILED TO VOID: " + authorization)
            
      # send an email here so we make sure this TX gets cleaned up
      begin
        email_body = "Payflow transaction needs to be voided for authorization: #{authorization}/#{payment_response.params['auth_code']}"
        m = Message.new(:to => User.admin.first.id, 
                        :title => "Unable to void $1 Authorization TX", 
                        :body => email_body)
        m.save!
      rescue
        logger.warn ("Unable to send admin email: #{email_body}");
      end
      
      return false
    end
    
    return true    
  end

  
end
