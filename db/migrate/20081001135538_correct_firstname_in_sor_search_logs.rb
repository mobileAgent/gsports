class CorrectFirstnameInSorSearchLogs < ActiveRecord::Migration
  def self.up    
    rename_column :sor_search_logs, :fisrtname, :firstname
  end

  def self.down    
    rename_column :sor_search_logs, :firstname, :fisrtname
  end
end
