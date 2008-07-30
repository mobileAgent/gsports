class UsersController < BaseController
  protect_from_forgery :only => [:create, :update, :destroy]
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
      :login => 'markdr_1217114297_biz@gmail.com',
      :password => 'markrmarkr',
      :partner => 'PayPal'
    })
    @response = gateway.purchase(@user.role.plan.cost, @credit_card)

#    if (@response.success?)  # Test gateway is a bit flakey
      m = Membership.new
      m.billing_method = Membership::CREDIT_CARD_BILLING_METHOD
      m.cost = @user.role.plan.cost
      m.name = @user.firstname + " " + @user.minitial + " " + @user.lastname

      # Note that this member has paid the first month
      history = MembershipBillingHistory.new
      history.authorization_reference_number = "sample"
      history.payment_method = Membership::CREDIT_CARD_BILLING_METHOD
      m.membership_billing_histories << history
      @user.memberships << m
      @user.save
#    else
#      render :action => 'billing', :userid => @user.id
#    end
    flash[:notice] = "Thanks for signing up! You should receive an e-mail confirmation shortly at #{@user.email}"

    redirect_to signup_completed_user_path(@user)
  end

  def change_team_photo
    @user = User.find(params[:id])
    if ((@user.team_staff? && current_user.id == @user.id) || current_user.admin?)
      @photo = Photo.find(params[:photo_id])
      @team = @user.team
      @team.avatar= @photo
      if @team.save!
        flash[:notice] = "Your changes were saved."
        redirect_to user_photo_path(@user, @photo)
      end
    end
  end
  
  def change_league_photo
    @user = User.find(params[:id])
    if ((@user.league_staff? && current_user.id == @user.id) || current_user.admin?)
      @photo = Photo.find(params[:photo_id])
      @league = @user.team.league
      @league.avatar= @photo
      if @team.save!
        flash[:notice] = "Your changes were saved."
        redirect_to user_photo_path(@user, @photo)
      end
    end
  end
  
end
