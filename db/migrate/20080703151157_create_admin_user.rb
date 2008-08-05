require 'active_record/fixtures'

class CreateAdminUser < ActiveRecord::Migration
  def self.up
    execute "insert into users (email,activated_at,login,salt,crypted_password,description,firstname,lastname,login_slug,role_id,birthday,address1,city,phone,created_at,updated_at) values ('#{ADMIN_EMAIL}','#{Time.now.to_s :db}','gsadmin','abcdefsaltydog','#{User.encrypt("gsadmin123","abcdefsaltydog")}','Global Sports Site Administrator','Ad','Ministrator','never-use-this-string',#{Role[:admin].id},'#{25.years.ago.to_date.to_s :db}','1 Global Sports Way','Annapolis','301.555.1212','#{Time.now.to_s :db}','#{Time.now.to_s :db}')"
  end

  def self.down
    user = User.find_by_email("#{ADMIN_EMAIL}")
    user.destroy if user
  end
  
end
