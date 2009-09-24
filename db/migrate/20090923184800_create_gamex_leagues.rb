class CreateGamexLeagues < ActiveRecord::Migration
  def self.up
    add_column :gamex_leagues, :release_time, :integer # wday * 24 * 60 + hour * 60 + min
  end

  def self.down
    remove_column :gamex_leagues, :release_time
  end
end
