class UsersController < BaseController
  protect_from_forgery :only => [:create, :update, :destroy]
  
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
    team = Team.find(:first)
    @user.team = team
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
      @user.make_member(Membership::CREDIT_CARD_BILLING_METHOD,nil,@response)

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
        @league = @user.team.league
        @league.avatar= @photo
        if @team.save!
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

end
