ActionController::Routing::Routes.draw do |map|
  
  map.resources :promotions
  map.resources :sent_messages
  map.resources :members
  map.resources :pages
  map.resources :teams
  map.resources :leagues
  map.resources :vidavees
  map.resources :video_assets, :new => { :save_video => :post, :swfupload => :post }, :collection => { :admin => :any }
  map.resources :video_clips
  map.resources :video_reels
  map.resources :messages
  map.resources :billing
  map.resources :monikers
  map.resources :subscription_plans
  map.resources :membership
  map.resources :staffs
  map.resources :purchase_orders
  map.resources :ratings
  map.resources :shared_access  
  map.resources :channels, :collection => { :add => :any, :playerVars => :any }
  
  map.resources :sessions, :collection => { :pop_login_box => :any }
  

  map.register         'register',        :controller => 'users', :action => 'register'
  map.forgot_password  'forgot_password', :controller => 'users', :action => 'forgot_password'

  # Override CE on this one by getting mine in there first
  map.admin_dashboard  '/admin/dashboard', :controller => 'admin', :action => 'dashboard'
  map.signup '/signup/:inviter_id/:inviter_code', :controller => 'users', :action => 'signup'
  map.teamname '/teamname/:team_name', :controller => 'teams', :action => 'show_by_name'

  # Turn on community engine routes
  map.from_plugin :community_engine

  # Add resources to the community engine routes
  map.resources :users, :member_path => '/:id', :nested_member_path => '/:user_id', :member => {
    :change_team_photo => :put,
    :change_league_photo => :put,
  } do |user|
    user.resources :messages
    user.resources :video_assets
    user.resources :video_clips
    user.resources :video_reels
    user.resources :photos, :collection => {:swfupload => :post, :slideshow => :get}
  end


  # Turn on the static pages with permalink routes
  map.info 'info/:permalink', :controller => 'pages', :action => 'show'

  # See how all your routes lay out with "rake routes"

  # Install the default routes as the lowest priority.
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'

  # A catch all route
  if ENV['RAILS_ENV'] == 'production' || ENV['RAILS_ENV'] == 'qa'
    map.connect '*path', :controller => 'base', :action => 'site_index'
  end
  
end


