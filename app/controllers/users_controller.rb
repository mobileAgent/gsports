class UsersController < BaseController

  if RAILS_ENV == 'production' || RAILS_ENV == 'qa'
    ssl_required :billing, :submit_billing, :edit_billing, :update_billing
  end
  
  protect_from_forgery :only => [:create, :update, :destroy]
  skip_before_filter :gs_login_required, :only => [:signup, :register, :new, :create, :billing, :submit_billing, :forgot_password, 
                                                   :registration_fill_team, :registration_fill_teams_by_state,
                                                   :registration_fill_league, :registration_fill_leagues_by_state,
                                                   :auto_complete_for_team_name, :auto_complete_for_league_name,
                                                   :ppv, :ppv_reg, :ppv_reg_create, :dashboard
                                                   ]
  
  skip_before_filter :billing_required, :only => [:billing, :edit_billing, :submit_billing, :update_billing, 
                                                  :account_expired, :membership_canceled, :renew, :cancel_membership, 
                                                  :auto_complete_for_team_name, :auto_complete_for_league_name,
                                                  :ppv, :ppv_reg, :ppv_reg_create, :dashboard
                                                  ]
  
  before_filter :admin_required, :only => [:logins, :assume, :destroy, :featured, :toggle_featured, :toggle_moderator, :disable, :registrations, :edit_promotion, :update_promotion ]
  before_filter :find_user, :only => [:edit, :edit_pro_details, :show, :update, :destroy, :statistics, :disable ]
  
  uses_tiny_mce(:options => AppConfig.gsdefault_mce_options.merge({:editor_selector => "rich_text_editor"}), 
                :only => [:new, :create, :update, :edit, :welcome_about])
  
  uses_tiny_mce(:options => AppConfig.narrow_mce_options.merge({:width => 300}),
                :only => [:show])
  
  VERIFICATION_COST = 9.99
  
  sortable_attributes :id, :firstname, :lastname, :team_id, :league_id, 'memberships.billing_method', :email, :role_id, 'teams.name', 'last', 'count', 'u.firstname', 'u.lastname', 'user_id'
  
  
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
    @clips.delete_if() { |v|
      !current_user.has_access?(v)
    }
    @reels = @user.video_reels.find(:all, :limit => 2, :order => "created_at DESC")
    @reels.delete_if() { |v|
      !current_user.has_access?(v)
    }
    @profile_clips_and_reels = []
    while(@profile_clips_and_reels.size < 2 && (@clips.size + @reels.size > 0))
      @profile_clips_and_reels << @clips.shift if @clips.size > 0
      @profile_clips_and_reels << @reels.shift if @reels.size > 0
    end
    @profile_videos = @user.video_users.find(:all, :limit => 2, :order => "created_at DESC")
    
    update_view_count(@user) unless current_user && current_user.eql?(@user)
  end

  # registration step 0, coming from an invitation link
  # need to grab the inviter stuff while it is hot
  def signup    
    session[:inviter_id] = params[:inviter_id]
    session[:inviter_code] = params[:inviter_code]
    _cleanup_session_for_signup

    redirect_to '/info/about'
  end

  # registration step 1
  def register
    @inviter_id = session[:inviter_id] || params[:inviter_id]
    @inviter_code = session[:inviter_code] || params[:inviter_code]

    @register_as = params[:as].to_i

    _cleanup_session_for_signup
  end

  # registration step 2
  def new
    _cleanup_session_for_signup
    
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
    
    
    # pass promo code
    @promocode ||= cookies[:promocode]
    @promoteam ||= cookies[:promoteam]
        
    # team override
    if @promoteam
      @team = Team.find(@promoteam)
      @teams = _get_teams_by_state @team.state_id
    end

    if cookies[:roster_invite_key]
      @roster_entry = RosterEntry.for_invite_key(cookies[:roster_invite_key]).first
      if @roster_entry
        @user.firstname = @roster_entry.firstname
        @user.lastname  = @roster_entry.lastname
        @user.phone     = @roster_entry.phone
        @user.email     = @roster_entry.email
      end
    end

    
    #render :action => 'new', :layout => 'beta' and return if AppConfig.closed_beta_mode
  end

  def ppv_reg
    @video_asset = VideoAsset.find(params[:id])
    @user = User.new(params[:user])
    @billing_address = Address.new(params[:billing_address])
    @credit_card = ActiveMerchant::Billing::CreditCard.new(params[:credit_card])
    @ppv_access = PPVAccess.new()
    @ppv_access.video_id = params[:id]
    @account_type = 'n'
    @purchase = 'd'

    ppv_prefill_payment

    if !session[:promo_id].nil?
      @promotion = Promotion.find(session[:promocode])
    end

    render :partial => 'ppv_reg'
  end

  def ppv
    
  end

  def ppv_reg_create

    #User.transaction do
    begin

      @ppv_access = PPVAccess.new(params[:ppv_access])
      @video_asset = VideoAsset.find(@ppv_access.video_id)
      @billing_address = Address.new(params[:billing_address])
      @credit_card = ActiveMerchant::Billing::CreditCard.new(params[:credit_card])
      @purchase = params[:purchase][:to_s] if params[:purchase]
      #@account_type = params[:account_type][:to_s] if params[:account_type]
      @account_type = (params[:login] && !params[:login].empty?) ? 'e' : 'n'

      ppv_process_user
      ppv_prefill_payment
      ppv_process_payment
      
      render :partial => 'ppv_pass'

    rescue ActiveRecord::RecordInvalid
      render :partial => 'ppv_reg'
    rescue ActiveRecord::StatementInvalid
      render :partial => 'ppv_reg'
    end

  end

  def ppv_process_user
#    if logged_in?
#      @user = current_user
#      user=User.authenticate(params[:login], params[:password])
#
#
#      @credit_card = @user.credit_card
#    else
      case @account_type
      when 'n'
    
        if !params[:tos] || !params[:suba]
          @user.errors.add_to_base("Please accept the Terms of Service and the Subscriber Agreement")
          raise ActiveRecord::RecordInvalid.new(@user)
        end
        
        @user = User.new(params[:user])
        @user.login= "gs#{Time.now.to_i}#{rand(1000)}"
        @user.phone = '-'
        @user.team_id = 1
        @user.league_id = 1

        @user.save!

        self.current_user = @user
        
        @credit_card.first_name = @user.firstname
        @credit_card.last_name = @user.lastname
        
      when 'e'
        #user=User.authenticate(params[:user][:email], params[:user][:password])
        user=User.authenticate(params[:login], params[:password])

        if user
          @user = user
          #@user.password = params[:user][:password]
          @user.password = params[:password]
          self.current_user = @user
          
          @credit_card = @user.credit_card
        else
          @user = User.new(params[:user])
          @user.errors.add_to_base("Email address and password are invalid.")
          raise ActiveRecord::RecordInvalid.new(@user)
        end
      end
#    end
  end

  def ppv_prefill_payment
    @billing_address.address1 = @user.address1
    @billing_address.address2 = @user.address2
    @billing_address.city = @user.city
    @billing_address.state = @user.state_id
    @billing_address.zip = @user.zip
  end

  def ppv_process_payment
    case @purchase
    when 'w'
      @cost = 2.99
      @expire = Time.now + (60 * 60 * 24) * 7
    when 'i'
      @cost = 4.99
      @expire = nil
    #when 'd'
    else
      @cost = 19.99
      @expire = Time.now + (60 * 60 * 24)
    end



    gateway = ActiveMerchant::Billing::PayflowGateway.new(
      :login => Active_Merchant_payflow_gateway_username,
      :password => Active_Merchant_payflow_gateway_password,
      :partner => Active_Merchant_payflow_gateway_partner)

    if !@purchase
      @user.errors.add_to_base("Please choose a duration for viewing.")
      raise ActiveRecord::RecordInvalid.new(@user)
    end


    if (!@credit_card.valid?)
      @credit_card.errors.add_to_base("Card information is not valid.")
      raise ActiveRecord::RecordInvalid.new(@credit_card)
    end

    @response = gateway.purchase(@cost, @credit_card, {:description=>"PPV Purchase for User ID: #{@user.id}"})

    logger.info "PPVREGWATCH * Response from gateway #{@response.inspect} for #{@user.full_name} at #{@cost}"

    if (!@response.success?)
      logger.info "PPVREGWATCH * Gatway response failed"

      if @response.nil? || @response.message.nil? || @response.message.blank?
        flash.now[:error] = "Sorry, we are having technical difficulties contacting our payment gateway. Try again in a few minutes."
      else
        flash.now[:error] = @response.message
      end

      @credit_card.errors.add_to_base(@response.message)

      raise ActiveRecord::RecordInvalid.new(@credit_card)
    end


    logger.info "PPVREGWATCH * Gatway response is success"

    credit_card_for_db = CreditCard.from_active_merchant_cc(@credit_card)
    credit_card_for_db.user = @user
    credit_card_for_db.save!


    @ppv_access.user = @user
    @ppv_access.cost = @cost
    @ppv_access.expires = @expire
    @ppv_access.save!



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
    # CAUTION: putting the user on the session risks overflowing the 4K cookie max
    #session[:reg_user] = @user     
    cookies.delete :reg_user_xml  
    
    # set the role id in case there are validation errors
    @requested_role = @role.id

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

        @league.attributes= params[:league]

      rescue ActiveRecord::RecordNotFound        
        # Should we try to find duplicates here or not?
        #@league = League.find(:first, :conditions => { :name => p_league[:name].to_i, :state_id => p_league[:state_id].to_i })
        
        @league = League.new params[:league]
        logger.debug "New league #{@league.name}"
      end

      # Not doing DB updates here yet. Wait until after payment
      # @league.save!
      #session[:reg_user_league] = @league
      _to_cookie @league
      
    when Role[:scout].id
      @user.team = User.admin.first.team
      @user.league = User.admin.first.league
      
    when Role[:team].id 
      begin
        @team = Team.find(params[:team][:id])
        logger.debug "Existing team found: #{@team.id}: #{@team.name}"

        @user.team = @team
        if (@team.league)
          @user.league = @team.league
        end

        @team_admin = @team.admin_user
        if @team_admin
           message = "#{@team.name} has already been registered by #{@team_admin.full_name}"
           logger.error message
           @team.errors.add('',message)
           raise Exception.new message
        end
        logger.debug "Updating attributes for team from form"

        @team.attributes= params[:team]

      rescue ActiveRecord::RecordNotFound        
        @team = Team.new params[:team]
        logger.debug "New team: #{@team.name}"
        if @team.league.nil?
          @team.league = User.admin.first.league
          logger.debug "Setting team league to admin value"
        end        
      end

      # REG_NO_SAVE
      # Not doing DB updates here yet. Wait until after payment
      # @team.save!

      #session[:reg_user_team] = @team
      _to_cookie @team
      
    else # when Role[:member].id
      begin
        @team = Team.find(params[:team][:id])
        @user.team = @team
        if (@team.league)
          @user.league = @team.league
        end
      rescue ActiveRecord::RecordNotFound        
        @team = Team.new params[:team]
        logger.debug "New team: #{@team.name}"
        if @team.league.nil?
          @team.league = User.admin.first.league
          logger.debug "Setting team league to admin value"
        end
      end

      # REG_NO_SAVE
      # Not doing DB updates here yet. Wait until after payment
      # @team.save!

      #session[:reg_user_team] = @team
      _to_cookie @team
      
    end
   
    #We never use this, but it is required for validation
    @user.login= "gs#{Time.now.to_i}#{rand(1000)}"

    # since the user gets put on the session, make sure we don't 
    # repeat any error reporting from previous cycles
    @user.errors.clear unless @user.nil?
    unless @user.valid?
      logger.warn "Have user validation errors"
      raise ActiveRecord::RecordInvalid.new(@user)
    end
    
    # since the team gets put on the session, make sure we don't 
    # repeat any error reporting from previous cycles
    @team.errors.clear unless @team.nil?
    if !@team.nil? && !@team.valid?
      logger.warn "Have team validation errors"
      raise ActiveRecord::RecordInvalid.new(@team)
    end
    
    # since the league gets put on the session, make sure we don't 
    # repeat any error reporting from previous cycles
    @league.errors.clear unless @league.nil?
    if !@league.nil? && !@league.valid?
      logger.warn "Have league validation errors"
      raise ActiveRecord::RecordInvalid.new(@league)
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
        session[:promo_id] = @promotion.id
      end
    end
    
    # REG_NO_SAVE
    # Not saving user to DB until after they have paid
    # @user.save!
    _to_cookie @user    

    create_friendship_with_inviter(@user, params)
    
    redirect_to :action => 'billing'

  rescue Exception => e
    logger.error "CAUGHT EXCEPTION #{e.message}"
    
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
    
    # make sure any updates to the user are saved on the session
    #session[:reg_user] = @user
    _to_cookie @user

    render :action => 'new'
  end  

  # registration step 3
  def billing
    #@user = session[:reg_user]
    @user = reg_user_from_cookie
    if @user.nil?
      id = params[:userid] || params[:id] || current_user.id
      if id
        @user = User.find(id)
      end
    end

    unless session[:promo_id].nil?
      @promotion = Promotion.find(session[:promo_id].to_i)
    end    
    
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
    #@user = session[:reg_user]
    @user = reg_user_from_cookie
    if @user.nil?
      id = params[:userid] || params[:id] || current_user.id
      if id
        @user = User.find(id)
      end
    end

    unless session[:promo_id].nil?
      @promotion = Promotion.find(session[:promo_id].to_i)
    end    
    
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

    # if the cost is 0, we need to make a $9.99, and then void it for verification 
    cost_for_gateway = @cost == 0 ? (VERIFICATION_COST * 100).to_i : (@cost * 100).to_i
    @response = gateway.purchase(cost_for_gateway, @credit_card, {:description=>"Registration for User ID: #{@user.id}"})

    logger.info "REGWATCH * Response from gateway #{@response.inspect} for #{@user.full_name} at #{cost_for_gateway}"
    
    if (@response.success?)
      logger.info "REGWATCH * Gatway response is success"

      # Void the $1.00 transaction post haste!
      if @cost == 0
        void_transaction(@response)
      end
      
      credit_card_for_db = CreditCard.from_active_merchant_cc(@credit_card)
      credit_card_for_db.user = @user
      credit_card_for_db.save!


    else
      logger.info "REGWATCH * Gatway response failed"
      @billing_address ||= Address.new
      
      if @response.nil? || @response.message.nil? || @response.message.blank?
        flash.now[:error] = "Sorry, we are having technical difficulties contacting our payment gateway. Try again in a few minutes."
      else
        @billing_gateway_error = "#{flash.now[:warning]} (#{@response.message})"
      end
      
      render :action => 'billing', :userid => @user.id
      return false
    end      

    # Are the team updates stashed in a cookie?
    @team = reg_team_from_cookie
    if @team
      logger.info "* Saving TEAM"
      @team.save!
      @user.team = @team
      @user.league = @team.league || User.admin.first.league
    end
    # Are the league updates stashed in a cookie?
    @league = reg_league_from_cookie
    if @league
      logger.info "* Saving LEAGUE"
      @league.save!
      @user.league = @league
      @user.team = User.admin.first.team
    end
    
    # fallback league and team settings
    @user.league = User.admin.first.league if @user.league.nil?
    @user.team = User.admin.first.team if @user.team.nil?
    
    @user.enabled = true
    @user.activated_at = Time.now if @user.activated_at.nil?

    logger.info "REGWATCH * Saving user record"
    @user.save!

    add_default_permissions(@user)

    if cookies[:roster_invite_key]
      @roster_entry = RosterEntry.for_invite_key(cookies[:roster_invite_key]).first
      #if @user.lastname == @roster_entry.lastname
      if @roster_entry 
        @roster_entry.reg_key = nil
        @roster_entry.user = @user
        @roster_entry.save()
        cookies.delete :roster_invite_key
      end
    end

    begin

      logger.info "REGWATCH * Saving USER Membership for user #{@user.id}"
      @user.make_member_by_credit_card(@cost,@billing_address,credit_card_for_db,@response,@promotion)

      if self.current_user.nil?
        logger.debug "REGWATCH * Logging the user in..."
        self.current_user = User.find(@user.id) # Log them in right now!
      end

    rescue Exception => e
      logger.info "REGWATCH * Saving USER Membership failed - #{e.message}"
      logger.info( "REGWATCH\n\n#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}\n\n" )


    end


    begin

      UserNotifier.deliver_welcome(@user)

    rescue Exception => e
      logger.info "REGWATCH * UserNotifier.deliver_welcome failed - #{e.message}"
      logger.info( "REGWATCH\n\n#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}\n\n" )
    end


    logger.info "REGWATCH * adding user to promotion access group?"
    #adding user to promotion access group
    begin
      if access_group = @promotion ? @promotion.access_group : nil
        logger.info "REGWATCH * promotion #{@promotion.inspect}, access group #{access_group.inspect}."
        access = AccessUser.new()
        access.user = @user
        access.access_group = access_group
        access.save
      end
    rescue Exception => e
      logger.info "REGWATCH * adding user to promotion access group failed - #{e.message}"
      logger.info( "REGWATCH\n\n#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}\n\n" ) #alt caller.join
    end



    redirect_to signup_completed_user_path(@user)
  end

  def add_default_permissions(user)

    scope = nil

    case user.role.id
    when Role[:team].id
      scope = user.team
    when Role[:league].id
      scope = user.league
    else
      return
    end

    Permission.staff_permission_list.each() { |permission,name|
      begin
        Permission.grant(user, permission, scope)
      rescue Exception=>e
        logger.warn "error granting permission for user:#{user.id}. #{e.message}"
      end
    }

  end
  
  def signup_completed
    _cleanup_session_for_signup
  end
  
  def account_expired
    _cleanup_session_for_signup
    @user = current_user
    @membership = @user.current_membership
  end
  
  def renew    
    _cleanup_session_for_signup

    if current_user && current_user.admin? && params[:id]
      @user = User.find(params[:id]) || current_user
    else
      @user = current_user
    end
    
    # Get the user's best/most-recent membership
    @membership = @user.current_membership
    
    # Pre-fill from the most recent membership, if available
    @billing_address = @membership ? @membership.address : Address.new
    
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
        session[:promo_id] = @promotion.id
      end
    end

    @cost = (@promotion && !@promotion.cost.nil?) ? @promotion.cost : @user.role.plan.cost
    render :action => 'billing', :userid => @user.id
  end
  
  def disable
    unless @user.admin?
      @user.enabled=false
      @user.save!
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

  def auto_complete_for_team_name
    if params[:team] && params[:team][:name]
      conditions = ["LOWER(name) like ?", params[:team][:name].downcase + '%' ]
      if params[:state_id]
        conditions[0] = conditions[0] + " and (state_id is null or state_id=?)"
        conditions[conditions.length] = params[:state_id].to_i
      end
      @teams = Team.find(:all, :conditions => conditions, :order => "name ASC", :limit => 10)
    end
    choices = "<%= content_tag(:ul, @teams.map { |t| content_tag(:li, h(t.name)) }) %>"    
    render :inline => choices
  end
  
  def auto_complete_for_league_name
    if params[:league] && params[:league][:name]
      conditions = ["LOWER(name) like ?", params[:league][:name].downcase + '%' ]
      if params[:state_id]
        conditions[0] = conditions[0] + " and (state_id is null or state_id=?)"
        conditions[conditions.length] = params[:state_id].to_i
      end
      @leagues = League.find(:all, :conditions => conditions, :order => "name ASC", :limit => 10)
      choices = "<%= content_tag(:ul, @leagues.map { |l| content_tag(:li, h(l.name)) }) %>"    
    end
    render :inline => choices
  end

  def auto_complete_for_team_league_name
    if params[:team] && params[:team][:league_name]
      conditions = ["LOWER(name) like ?", params[:team][:league_name].downcase + '%' ]
      if params[:state_id]
        conditions[0] = conditions[0] + " and (state_id is null or state_id=?)"
        conditions[conditions.length] = params[:state_id].to_i
      end
      @leagues = League.find(:all, :conditions => conditions, :order => "name ASC", :limit => 10 )
      choices = "<%= content_tag(:ul, @leagues.map { |l| content_tag(:li, h(l.name)) }) %>"    
    end
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
    if current_user.role.nil?
      flash[:notice] = "Upgrade to full membership to access more site features."
      redirect_to '/users/ppv'
    else
      redirect_to team_path(current_user.team)
    end
  end
  
  def old_dashboard  
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
    if @existing_credit_card.nil? || !@credit_card.equals?(@existing_credit_card)
      logger.debug "Saving changes to credit card..."
      @credit_card.save!
      
      if @membership
        @membership.credit_card = @credit_card
      end
    end

    if @membership
      logger.debug "Saving membership(s)..."
      @membership.address = @billing_address
      @membership.save!
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
        @cost = @user.role.plan.cost
      end
      
      # no decimals posted to gateway
      cost_for_gateway = (@cost * 100).to_i
      
      # make the purchase
      @response = gateway.purchase(cost_for_gateway, @am_credit_card, {:description=>"Update Billing for User ID: #{@user.id}"})
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
        return false
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
      @membership.cancel! params[:cancellation][:reason]      
      
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

  
  def reg_team_from_cookie
    logger.debug "Parsing registration team cookie"
    if session[:reg_team_id]
      team = Team.find session[:reg_team_id].to_i
    end
    unless cookies[:reg_team_xml].blank?
      xml = cookies[:reg_team_xml]
      logger.debug "#{xml}"
      if team.nil?
        team = Team.new
      end
      team.from_xml xml
    end
  end

  def reg_league_from_cookie
    logger.debug "Parsing registration league cookie"
    if session[:reg_league_id]
      league = League.find session[:reg_league_id].to_i
    end
    unless cookies[:reg_league_xml].blank?
      xml = cookies[:reg_league_xml]
      logger.debug "#{xml}"
      if league.nil?
        league = League.new
      end
      league.from_xml xml
    end
  end

  def reg_user_from_cookie
    logger.debug "Parsing registration user cookie"
    unless cookies[:reg_user_xml].blank?
      xml = cookies[:reg_user_xml]
      logger.debug "#{xml}"
      user = User.new.from_xml xml
      if session[:reg_user_role_id]
        logger.debug "Role ID from session #{session[:reg_user_role_id].to_i}"
        user.role_id = session[:reg_user_role_id].to_i
      end
      if session[:reg_user_password]
        user.password = session[:reg_user_password]
        user.password_confirmation = session[:reg_user_password]
      end
      user
    end
  end

  def registrations
    @users = User.paginate :all, :order=>sort_order, :include => [ :memberships, :team ], :page => params[:page]
  end

  def edit_promotion
    @user = User.find(params[:id])
    @membership = @user.current_membership
    @promotion = @membership.promotion
    @promotions = Promotion.find(:all, :conditions=>'enabled = 1')
  end

  
  def update_promotion

    @user = User.find(params[:id])
    @membership = @user.current_membership.renew
        
    @promotion = Promotion.find(params['promotion']['id'])
    
    @membership.apply_promotion(@promotion) if @membership

    if @membership && @membership.save
      redirect_to '/users/registrations'
    else
      @promotion.errors.add('','Could not renew membership') if @membership.nil?
      @promotions = Promotion.find(:all, :conditions=>'enabled = 1')
      render :action => :edit_promotion
    end
    
  end

  def logins
    @logins = Activity.logins(sort_order).paginate(:order=>sort_order, :page => params[:page])
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
     
    logger.debug ("*** VOIDING Temporary Authorization TX: " + authorization)
    
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
        m = Message.new(:to_id => User.admin.first.id, 
                        :title => "Unable to void Authorization TX", 
                        :body => email_body)
        m.save!
      rescue
        logger.warn ("Unable to send admin email: #{email_body}")
      end
      
      return false
    end
    
    return true    
  end

  def _cleanup_session_for_signup
    session[:promo_id] = nil
    session[:reg_team_id] = nil
    session[:reg_league_id] = nil
    session[:reg_user_role_id] = nil
    session[:reg_user_password] = nil
    session[:purchase_order] = nil

    if cookies.size
      logger.debug "Deleting registration cookies (#{cookies.size} total cookies)"
      cookies.delete :reg_user_xml unless cookies[:reg_user_xml].blank?
      cookies.delete :reg_team_xml unless cookies[:reg_team_xml].blank?
      cookies.delete :reg_league_xml unless cookies[:reg_league_xml].blank?
      logger.debug "Have #{request.cookies.size} cookies"
    end

  end   
  
  def _to_cookie(record, options = {})
    logger.debug "Called to_cookie for ... #{record}"
    options.merge! (:skip_instruct => true, :skip_types => true, :only => record.attributes.reject { |k,v| v.nil? || v.blank? }.keys)
    c = record.to_xml options

    if Team === record
      logger.debug("Team to cookie...")
      session[:reg_team_id] = record.id.to_s unless record.id.nil?
      cookies[:reg_team_xml] = c
    elsif League === record
      logger.debug("League to cookie...")
      session[:reg_league_id] = record.id.to_s unless record.id.nil?
      cookies[:reg_league_xml] = c
    elsif User === record
      logger.debug("User to cookie...")
      # extract protected attributes here and put on the session separately
      session[:reg_user_role_id] = record.role_id.to_s unless record.role_id.nil?
      session[:reg_user_password] = record.password unless record.password.nil?
      cookies[:reg_user_xml] = c
    end
  end
  

end
