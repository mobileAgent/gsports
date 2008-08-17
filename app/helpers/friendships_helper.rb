module FriendshipsHelper

  def friendship_control_links(friendship)
    case friendship.friendship_status_id
      when FriendshipStatus[:pending].id
        links = []
        if !friendship.initiator?
          links << ['Accept', accept_user_friendship_path(friendship.user, friendship), {:method => :put, :class => 'button positive genericButton'} ] #unless friendship.initiator?
        end
        links << ['Deny', deny_user_friendship_path(friendship.user, friendship), {:method => :put, :class => 'button negative genericButton'} ]
      when FriendshipStatus[:accepted].id  
        [
          ['Send Message', new_message_path(:to => friendship.friend.id), {:class => 'genericButton'} ],
          ["Remove this friend", deny_user_friendship_path(friendship.user, friendship), {:method => :put, :class => 'button negative genericButton'} ]
        ]
      when FriendshipStatus[:denied].id
    		[ 
    		  ["Accept this request", accept_user_friendship_path(friendship.user, friendship), {:method => :put, :class => 'button positive genericButton'} ]
    		]
    end
  end

end
