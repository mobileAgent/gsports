class FriendshipsController < BaseController
  
  # POST /friendships
  # POST /friendships.xml
  # copied just to replace @friend.login with @friend.full_name
  def create
    @user = User.find(params[:user_id])
    @friendship = Friendship.new(:user_id => params[:user_id], :friend_id => params[:friend_id], :initiator => true )
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
        format.js { render( :inline => "Requested friendship with #{@friendship.friend.full_name}." ) }        
      else
        flash.now[:error] = 'Friendship could not be created'
        @users = User.find(:all)
        format.html { redirect_to user_friendships_path(@user) }
        format.js { render( :inline => "Friendship request failed." ) }                
      end
    end
  end
  
end
