class ChangeCategoriesSupportHighlightedAthlete < ActiveRecord::Migration
  def self.up
    execute "update categories set name = 'General Sports' where id = 1"
    execute "update categories set name = 'Questions and Help' where id = 2"
    execute "update categories set name = 'I Remember When...' where id = 3"
    execute "update categories set name = 'The Business of Sports' where id = 4"
    execute "update categories set name = 'Taking It To The Next Level' where id = 5"
    execute "update categories set name = 'Miscellaneous' where id = 6"
    execute "insert into categories (name,tips,new_post_text,nav_text) values ('Athlete Of The Week','Used by team and league staff for feature stories','New Athlete Of The Week','Athlete Of The Week')"
  end

  def self.down
    execute "delete from categories where name = 'Athlete Of The Week'"
  end
end
