module FriendshipsHelper

  def friendship_control_links(friendship)
    case friendship.friendship_status_id
      when FriendshipStatus[:pending].id
        links = []
        if !friendship.initiator?
          links << ['Accept', accept_user_friendship_path(friendship.user, friendship), {:method => :put, :class => 'button positive'} ] #unless friendship.initiator?
        end
        links << ['Deny', deny_user_friendship_path(friendship.user, friendship), {:method => :put, :class => 'button negative'} ]
      when FriendshipStatus[:accepted].id  
        [
          ['Send Message', new_message_path(:to => friendship.friend.id), {} ],
          ["Remove this friend", deny_user_friendship_path(friendship.user, friendship), {:method => :put, :class => 'button negative'} ]
        ]
      when FriendshipStatus[:denied].id
    		[ 
    		  ["Accept this request", accept_user_friendship_path(friendship.user, friendship), {:method => :put, :class => 'button positive'} ]
    		]
    end
  end

end
