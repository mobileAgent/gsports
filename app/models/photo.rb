require 'vendor/plugins/community_engine/app/models/photo'

class Photo < ActiveRecord::Base
  
  belongs_to :team
  has_one :team_as_avatar, :class_name => "Team", :foreign_key => "avatar_id"
  belongs_to :league
  has_one :league_as_avatar, :class_name => "League", :foreign_key => "avatar_id"

  before_destroy { |item| Favorite.destroy_all "favoritable_id = #{item.id} and favoritable_type = '#{item.type.to_s}'" }

end
