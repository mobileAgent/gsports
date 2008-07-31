require 'vendor/plugins/community_engine/app/models/favorite'

class Favorite < ActiveRecord::Base
  
  named_scope :ftype,
     lambda { |favoritable_type| { :conditions => ["favoritable_type = ?", favoritable_type] } }
  
  named_scope :ftypes,
    lambda { |*args| { :conditions => ["favoritable_type IN (?)", args] } }

  named_scope :user,
     lambda { |user| { :conditions => ["user_id = ?",user.id] } }

  named_scope :item,
    lambda { |item| { :conditions => ["favoritable_type = ? and favoritable_id = ?",
                                      item.class.to_s,item.id] } }

  named_scope :item_type_id,
     lambda { |item_type, item_id| { :conditions => ["favoritable_type = ? and favoritable_id = ?",
                                                   item_type,item_id] } }
  
  named_scope :videos, 
     :conditions => ["favoritable_type IN (?)",["VideoAsset","VideoReel","VideoCLip"]]

  def self.favorite? (user, item)
    Favorite.user(user).item(item).count > 0
  end

  def self.count_for_item(item)
    Favorite.item(item).count
  end
  
end
