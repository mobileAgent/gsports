module AccessGroupsHelper
  
  def add_video_to_access_group_path(add)
    "/access_groups/add_video?access_item[item_type]=#{add.class}&access_item[item_id]=#{add.id}"
  end
  
  def add_user_to_access_group_path(add)
    "/access_groups/add_user?access_user[user_id]=#{add.id}"
  end
  
end
