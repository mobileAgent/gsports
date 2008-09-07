require 'vendor/plugins/community_engine/app/models/friendship'
class Friendship < ActiveRecord::Base
  @@daily_request_limit = 50
end
