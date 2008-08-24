class DeletedVideo < ActiveRecord::Base
  belongs_to :user, :foreign_key=>'deleted_by'
end
