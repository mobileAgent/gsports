module AccessGroupsHelper
  
  def add_video_to_access_group_path(add)
    "/access_groups/add_video?access_item[item_type]=#{add.class}&access_item[item_id]=#{add.id}"
  end
  
  def add_user_to_access_group_path(add)
    "/access_groups/add_user?access_user[user_id]=#{add.id}"
  end
  
  
  def users_access_group_path(grp)
    "/access_groups/users/#{grp.id}"
  end
  
  def items_access_group_path(grp)
    "/access_groups/items/#{grp.id}"
  end
  
  
  
  def get_restriction item
    AccessItem.restriction_for item
  end
  
  def get_access user
    AccessUser.access_for user
  end
  
end
