class AddPagesInstances < ActiveRecord::Migration
  def self.up
    execute "insert into pages (name,permalink,content,html_content,created_at,updated_at) values ('Membership','membership','Initial membership content','Initial membership content','#{Time.now.to_s :db}','#{Time.now.to_s :db}')"
  end

  def self.down
    execute "delete from pages where permalink = 'membership'"
  end
end
