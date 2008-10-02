class Search
  
  ALL      = 0
  VIDEO    = 1
  USERS    = 2
  BLOGS    = 3
  TEAMS    = 4
  LEAGUES  = 5
  
  TEAM_USERS   = 10
  LEAGUE_USERS = 11
  FRIENDS      = 13
  
  def self.top_nav_options
    [
      [ ALL,     'All' ],
      [ VIDEO,   'Videos' ],
      [ USERS,   'Users' ],
      [ TEAMS,   'Teams' ],
      [ LEAGUES, 'Leagues' ],
      [ BLOGS,   'Blogs' ],
    ]
  end
  
end
