class UsersController < BaseController

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

  def submit_billing
    @user = User.find(params[:userid].to_i)
    billing_info = params[:billing]

    gateway = ActiveMerchant::Billing::BraintreeGateway.new({
      :login => 'demo',
      :password => 'password'
    })

    @credit_card = ActiveMerchant::Billing::CreditCard.new({
      :first_name => billing_info[:firstname],
      :last_name => billing_info[:lastname],
      :number => billing_info[:cardnumber],
      :month => billing_info["date(2i)"],
      :year => billing_info["date(1i)"],
      :verification_value => billing_info[:verificationnumber]
    })
    if (!@credit_card.valid?)
      renderkkk :action => 'billing', :userid => @user.id
      return
    end
    response = gateway.purchase(100, @credit_card)
    logger.debug "RESPONSE:" + response.inspect

    flash[:notice] = "Thanks for signing up! You should receive an e-mail confirmation shortly at #{@user.email}"

    redirect_to signup_completed_user_path(@user)
  end

end
