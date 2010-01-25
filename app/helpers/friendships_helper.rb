module FriendshipsHelper

  def friendship_control_links(friendship,owner,current_user)
    links = []
    posButtonOpts = {:method => :put, :class => 'button positive genericButton'}
    negButtonOpts = {:method => :put, :class => 'button negative genericButton'}
    if (current_user.id == owner.id)
      if friendship.user_id == current_user.id
        case friendship.friendship_status_id
        when FriendshipStatus[:pending].id
          if !friendship.initiator?
            links << ['Accept', accept_user_friendship_path(friendship.user, friendship), posButtonOpts ]
          end
          links << ['Deny', deny_user_friendship_path(friendship.user, friendship), negButtonOpts ]
        when FriendshipStatus[:accepted].id  
          links << ['Send Message', new_message_path(:to_id => friendship.friend.id), posButtonOpts ]
          links << ["Remove this friend", deny_user_friendship_path(friendship.user, friendship), negButtonOpts ]
        when FriendshipStatus[:denied].id
          links << ["Accept this request", accept_user_friendship_path(friendship.user, friendship), posButtonOpts ]
        end
      end
    elsif friendship.friend_id != current_user.id
      if current_user.friendships.collect(&:friend_id).member?(friendship.friend_id)
        if (current_user.accepted_friendships.collect(&:friend_id).member?(friendship.friend_id))
            links << ['Send Message', new_message_path(:to_id => friendship.friend.id), posButtonOpts ]
        end
      end
    end
    if (friendship.friend.accepted_friendships.size > 1)
      links << [ "See #{friendship.friend.accepted_friendships.size} Friends", accepted_user_friendships_path(friendship.friend), {:class => 'genericButton'}]
    end
    links
  end

end
