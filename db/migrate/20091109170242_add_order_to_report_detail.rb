class AddOrderToReportDetail < ActiveRecord::Migration
  def self.up
    add_column :report_details, :orderby, :integer
    remove_column :report_details, :post_id
  end

  def self.down
    add_column :report_details, :post_id, :integer
    remove_column :report_details, :orderby
  end
end
