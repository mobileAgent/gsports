class CreateReports < ActiveRecord::Migration

  def self.up

    create_table :reports do |t|

      t.string   :name
      t.integer  :author_id
      t.string   :owner_type
      t.integer  :owner_id
      t.integer  :access_group_id
      t.string   :report_type, :limit=>30
      t.string   :description


    end

    create_table :report_details do |t|

      t.integer  :report_id
      t.string   :video_type
      t.integer  :video_id
      t.integer  :post_id

    end

  end

  def self.down
    drop_table :reports
    drop_table :report_details
  end

end
