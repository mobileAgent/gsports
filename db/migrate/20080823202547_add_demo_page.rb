class AddDemoPage < ActiveRecord::Migration
  def self.up
    %W(demo).each do |page|
      execute "insert into pages (name,permalink,content,html_content,created_at,updated_at) values ('#{page}','#{page}','Initial #{page} content','Initial #{page} content','#{Time.now.to_s :db}','#{Time.now.to_s :db}')"
    end
  end

  def self.down
    %W(demo).each do |page|
      execute "delete from pages where permalink = '#{page}'"
    end
  end
end
