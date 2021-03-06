require 'vendor/plugins/community_engine/app/models/favorite'

class Favorite < ActiveRecord::Base

  VIDEO_FAVORITE_TYPES = [VideoAsset.to_s,VideoReel.to_s,VideoClip.to_s,VideoUser.to_s]
  
  named_scope :ftype,
     lambda { |favoritable_type| { :conditions => ["favoritable_type = ?", favoritable_type] } }
  
  named_scope :ftypes,
    lambda { |*args| { :conditions => ["favoritable_type IN (?)", args] } }

  named_scope :user,
     lambda { |user| { :conditions => ["user_id = ?",user.id] } }

  named_scope :users,
     lambda { |user_ids| { :conditions => ["user_id IN (?)",user_ids] } }

  named_scope :item,
    lambda { |item| { :conditions => ["favoritable_type = ? and favoritable_id = ?",
                                      item.class.to_s,item.id] } }

  named_scope :item_type_id,
     lambda { |item_type, item_id| { :conditions => ["favoritable_type = ? and favoritable_id = ?",
                                                   item_type,item_id] } }
  
  named_scope :videos, 
     :conditions => ["favoritable_type IN (?)",VIDEO_FAVORITE_TYPES]

  named_scope :featured_games,
    lambda {|userids| {:conditions => ["user_id IN (?) and favoritable_type = ?",userids,VideoAsset.to_s], :order => "created_at DESC", :limit => 2} }

  named_scope :for_team_staff, lambda { |team| { 
    :joins => :user, 
    :conditions => ["users.team_id = ? and (users.role_id = ? or users.role_id = ?)", (team.type == Team ? team.id : team), Role[:team].id, Role[:team_staff].id] 
  } }

  named_scope :for_league_staff, lambda { |league| { 
    :joins => :user, 
    :conditions => ["users.league_id = ? and (users.role_id = ? or users.role_id = ?)", (league === League ? league.id : league), Role[:league].id, Role[:league_staff].id] 
  } }

  def self.favorite? (user, item)
    Favorite.user(user).item(item).count > 0
  end

  def self.count_for_item(item)
    Favorite.item(item).count
  end

  def video_type?
    favoritable_type && VIDEO_FAVORITE_TYPES.member?(favoritable_type.to_s)
  end

end
