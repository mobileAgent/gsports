#
# Organization is the common features between Teams and Leagues
#
# to properly include this module, implement the following methods in the class including Organization
#
# get_org_id_from_object(o) - extract an organization id from an object, team_id, league_id are the usual
# get_self() - return self for containing object
#
# i.e
# 
# class Team
#
#   def get_org_id_from_object(o)
#     case o
#     when NilClass
#       nil
#     else
#       o.team_id
#     end
#   end
#
#   def get_self()
#     self
#   end
#
# end
#

module Organization



  ### Channel Publication

  PUBLISH_ASSETS = 1
  PUBLISH_CLIPS = 2
  PUBLISH_REELS = 4
  PUBLISH_MASK = PUBLISH_ASSETS | PUBLISH_CLIPS | PUBLISH_REELS

  def can_publish?(item=nil)
    can = false
    if can_publish.to_i > 0
      case item
      when NilClass
        can = true
      when VideoAsset
        can = get_publish_feature(PUBLISH_ASSETS) && get_org_id_from_object(item) == id; #item.team_id
      when VideoClip
        can = get_publish_feature(PUBLISH_CLIPS)
      when VideoReel
        can = get_publish_feature(PUBLISH_REELS)
      else
        can = false
      end
    end
    can
  end

  def can_publish_assets
    get_publish_feature PUBLISH_ASSETS
  end

  def can_publish_assets=(bool)
    set_publish_feature(bool, PUBLISH_ASSETS)
  end

  def can_publish_clips
    get_publish_feature PUBLISH_CLIPS
  end

  def can_publish_clips=(bool)
    set_publish_feature(bool, PUBLISH_CLIPS)
  end

  def can_publish_reels
    get_publish_feature PUBLISH_REELS
  end

  def can_publish_reels=(bool)
    set_publish_feature(bool, PUBLISH_REELS)
  end


  protected


  def get_publish_feature(feature)
    (can_publish.to_i & feature) != 0
  end

  def set_publish_feature(bool, feature)
    logger.info "!!!!!!!!!! #{self.class} #{id} #{name} #{can_publish}"
    logger.info "!!!!!!!!!! #{can_publish}"
    bool = false if bool.is_a?(String) and bool.empty?
    get_self().can_publish = bool ? (can_publish.to_i | feature) : (can_publish.to_i & (PUBLISH_MASK - feature))
    logger.info "!!!!!!!!!! #{can_publish}"
      logger.info "!!!!!!!!!! #{self.class} #{id} #{name} #{can_publish}"
        logger.info "!!!!!!!!!!"
  end
  
  ###
  
  
  
end

