class CreateMessages < ActiveRecord::Migration
  def self.up
    create_table "messages", :force => true do |t|
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "title"
      t.text     "body"
      t.integer  "read",     :limit => 1
      t.integer  "replied",  :limit => 1
      t.integer  "to_id",    :limit => 11
      t.integer  "from_id",  :limit => 11
    end
  end

  def self.down
    drop_table :messages
  end
end
