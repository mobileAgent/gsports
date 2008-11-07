class FriendshipsController < BaseController
  
  # POST /friendships
  # POST /friendships.xml
  # copied just to replace @friend.login with @friend.full_name
  def create
    @user = User.find(params[:user_id] || current_user.id)
    @friendship = Friendship.new(:user_id => @user.id, :friend_id => params[:friend_id], :initiator => true )
    @friendship.friendship_status_id = FriendshipStatus[:pending].id    
    reverse_friendship = Friendship.new(params[:friendship])
    reverse_friendship.friendship_status_id = FriendshipStatus[:pending].id 
    reverse_friendship.user_id, reverse_friendship.friend_id = @friendship.friend_id, @friendship.user_id
    
    respond_to do |format|
      if @friendship.save && reverse_friendship.save
        UserNotifier.deliver_friendship_request(@friendship) if @friendship.friend.notify_friend_requests?
        format.html {
          flash[:notice] = "Requested friendship with #{@friendship.friend.full_name}."
          redirect_to accepted_user_friendships_path(@user)
        }
        format.js { render :action => "create" }
        #
        #  if params[:listing]
        #    # just clear out the add-friend button
        #    render( :inline => "" ) 
        #  else
        #    render( :inline => "Requested friendship with #{@friendship.friend.full_name}." ) 
        #  end
        #}        
      else
        logger.error("Friendship request failed #{@friendship.errors.inspect} and on the reverse #{reverse_friendship.errors.inspect}")
        flash[:error] = 'Friendship could not be created'
        # @users = User.find(:all) -- wtf?
        format.html { redirect_to accepted_user_friendships_path(@user) }
        #format.js { render( :inline => "Friendship request failed." ) }                
        format.js { render :action => "create" }
      end
    end
  end
  
end
