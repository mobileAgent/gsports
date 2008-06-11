require 'vendor/plugins/community_engine/app/models/role'
class Role < ActiveRecord::Base
  belongs_to :subscription_plan
end