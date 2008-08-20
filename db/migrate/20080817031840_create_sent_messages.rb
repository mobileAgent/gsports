class CreateSentMessages < ActiveRecord::Migration
  def self.up
    create_table :sent_messages do |t|
      t.string :title
      t.integer :from_id, :null => :false
      t.string :to_ids, :null => :false
      t.text :body

      t.timestamps
    end
  end

  def self.down
    drop_table :sent_messages
  end
end
