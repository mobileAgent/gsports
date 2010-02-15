class Parent < ActiveRecord::Base

  validates_presence_of :roster_entry

  belongs_to :roster_entry
  belongs_to :user


  
end