class AthleteOfTheWeek < Post

  # "Athlete Of The Week"
  CATEGORY_NAME = self.to_s.titleize

  attr_accessor :photo_id

  def self.my_category
    Category.find_by_name(CATEGORY_NAME)
  end

  # This is a wrapper around posts in a certain category. 
  # The athletes of the week for a league or team will be the
  # two most recent posts to that category by any member of the
  # respective team of league staff.
  def self.for_team(team_id)
    team_staff_ids = User.team_staff(team_id).collect(&:id)
    return [] if(my_category.nil? || team_staff_ids.empty?)
    AthleteOfTheWeek.find(:all, 
                          :conditions => ["category_id = ? and user_id IN (?) ", my_category.id, team_staff_ids], 
                          :order => "published_at DESC",
                          :include => :user,
                          :limit => 2)
  end

  def self.for_league(league_id)
    league_staff_ids = User.league_staff(league_id).collect(&:id)
    return [] if(my_category.nil? || league_staff_ids.empty?)
    AthleteOfTheWeek.find(:all, 
                          :conditions => ["category_id = ? and user_id IN (?) ", my_category.id, league_staff_ids],
                          :include => :user,
                          :order => "published_at DESC", 
                          :limit => 2)
  end
  
  # The athletes of the week for the home page will be the
  # chosen randomly from among recent team and league
  # athletes of the week.
  def self.for_home_page
    legal_role_ids = [
                      Role[:league].id,
                      Role[:league_staff].id,
                      Role[:team].id,
                      Role[:team_staff].id,
                      Role[:admin].id
                     ]
    
    posts = AthleteOfTheWeek.find(:all,
      :conditions => ["category_id = ? and users.role_id IN (?) and published_at > ?",
                      my_category.id,legal_role_ids,28.days.ago],
      :include => [:user],
      :order => "published_at DESC")

    # If we have none, 1 or 2, just let them go
    return posts if posts.size <= 2
    
    # Pick two at random from the list
    post1 = posts[rand(posts.size)]
    post2 = nil
    while (post2.nil? || post1.id == post2.id)
      post2 = posts[rand(posts.size)]
    end

    [post1,post2]
  end

end
