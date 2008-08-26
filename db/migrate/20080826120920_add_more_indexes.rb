class AddMoreIndexes < ActiveRecord::Migration
  def self.up
    add_index :posts, :published_at
    add_index :posts, :published_as
    add_index :activities, :created_at
    add_index :activities, :user_id
    add_index :comments, [:commentable_id, :commentable_type]
  end

  def self.down
    remove_index :posts, :published_at
    remove_index :posts, :published_as
    remove_index :activities, :created_at
    remove_index :activities, :user_id
    remove_index :comments, [:commentable_id, :commentable_type]
   end
end
