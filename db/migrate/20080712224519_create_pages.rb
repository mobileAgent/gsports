require 'active_record/fixtures'

class CreatePages < ActiveRecord::Migration
  def self.up
    create_table :pages do |t|
      t.string :name
      t.string :permalink
      t.text :content
      t.text :html_content
      t.timestamps
    end

    directory = File.join(File.dirname(__FILE__),"dev_data")
    Fixtures.create_fixtures(directory,"pages")
    
  end
  
  def self.down
    drop_table :pages
  end
end
