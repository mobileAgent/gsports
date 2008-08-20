module FriendshipsHelper

  def friendship_control_links(friendship,current_user)
    links = []
    if friendship.user.id == current_user.id
      case friendship.friendship_status_id
      when FriendshipStatus[:pending].id
        if !friendship.initiator?
          links << ['Accept', accept_user_friendship_path(friendship.user, friendship), {:method => :put, :class => 'button positive genericButton'} ] #unless friendship.initiator?
        end
        links << ['Deny', deny_user_friendship_path(friendship.user, friendship), {:method => :put, :class => 'button negative genericButton'} ]
      when FriendshipStatus[:accepted].id  
        links << ['Send Message', new_message_path(:to => friendship.friend.id), {:class => 'genericButton'} ]
        links << ["Remove this friend", deny_user_friendship_path(friendship.user, friendship), {:method => :put, :class => 'button negative genericButton'} ]
        if (friendship.friend.accepted_friendships.size > 1)
          links << [ "See #{friendship.friend.accepted_friendships.size} Friends", accepted_user_friendships_path(friendship.friend), {:class => 'genericButton'}]
        end
      when FriendshipStatus[:denied].id
        links << ["Accept this request", accept_user_friendship_path(friendship.user, friendship), {:method => :put, :class => 'button positive genericButton'} ]
      end
    elsif friendship.friend_id != current_user.id
      links << ['Request Friendship',url_for({ :controller => 'friendships', :action => 'create', :user_id => current_user.id, :friend_id => friendship.friend_id}), {:method => :post, :class => 'genericButton'}]
    end
    links
  end

end
