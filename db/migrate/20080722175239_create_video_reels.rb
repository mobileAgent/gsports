class CreateVideoReels < ActiveRecord::Migration
  def self.up
    create_table :video_reels do |t|
      t.string :title
      t.string :description
      t.integer :user_id
      t.string :dockey

      t.timestamps
    end
  end

  def self.down
    drop_table :video_reels
  end
end
