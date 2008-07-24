ActionController::Routing::Routes.draw do |map|

  
  map.resources :members
  map.resources :pages
  map.resources :teams
  map.resources :leagues
  map.resources :vidavees
  map.resources :video_assets, :new => { :save_video => :post, :swfupload => :post }
  map.resources :video_clips
  map.resources :video_reels
  map.resources :messages

  map.register         'register',        :controller => 'users', :action => 'register'
  map.forgot_password  'forgot_password', :controller => 'users', :action => 'forgot_password'
  
  # Turn on community engine routes
  map.from_plugin :community_engine

  # Add resources to the community engine routes
  map.resources :users, :member_path => '/:id', :nested_member_path => '/:user_id', :member => {} do |user|
    user.resources :video_assets
    user.resources :video_clips
    user.resources :video_reels
  end

  
  # Turn on the static pages with permalink routes
  map.info 'info/:permalink', :controller => 'pages', :action => 'show'

  # See how all your routes lay out with "rake routes"

  # Install the default routes as the lowest priority.
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
end
