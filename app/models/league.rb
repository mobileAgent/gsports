class League < ActiveRecord::Base

  has_many :video_assets
  has_many :teams
  has_many :users, :through => :teams, :source => :users
  belongs_to :state
  belongs_to :avatar, :class_name => "Photo", :foreign_key => "avatar_id"
  
  before_destroy :reassign_dependent_items
  
  # Every league needs a name
  validates_presence_of :name

  alias_method :league_avatar, :avatar
  
  def self.find_list(tag_list)
    find(:all, :conditions => [ 'LOWER(name) LIKE ?', '%' + tag_list + '%' ])
  end

  def state_name
    state ? state.name : nil
  end

  def league_name
    self.name
  end
  
  def avatar_photo_url(size = nil)
    if avatar
      avatar.public_filename(size)
    else
      case size
        when :thumb
          AppConfig.photo['missing_thumb']
        else
          AppConfig.photo['missing_medium']
      end
    end
  end
  
  protected

  def reassign_dependent_items
    alg_id = User.admin.first.league_id
    v = VideoAsset.find_all_by_league_id(self.id)
    v.each { |x| x.update_attributes(:league_id => alg_id) }

    u = User.find_all_by_league_id(self.id)
    u.each { |x| x.update_attributes(:league_id => alg_id) }

    t = Team.find_all_by_league_id(self.id)
    t.each { |x| x.update_attributes(:league_id => alg_id) }
                                   
    p = Post.find_all_by_league_id(self.id)
    p.each { |x| x.update_attributes(:league_id => alg_id) }
    
  end
  
end
