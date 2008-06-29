require 'active_record/fixtures'

class CreateVidavees < ActiveRecord::Migration
  def self.up
    create_table :vidavees do |t|
      t.string :uri
      t.string :servlet
      t.string :key
      t.string :secret
      t.string :context
      t.string :username
      t.string :password

      t.timestamps
    end

    directory = File.join(File.dirname(__FILE__),"dev_data")
    Fixtures.create_fixtures(directory,"vidavees")
    
  end

  def self.down
    drop_table :vidavees
  end
end
