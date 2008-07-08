class CreateAdminUser < ActiveRecord::Migration
  def self.up
    user = User.new
    user.email= 'admin@globalsports.net'
    user.activated_at= DateTime.now
    user.login= 'gsadmin'
    user.description= 'Global Sports Site Administrator'
    user.firstname= 'Ad'
    user.lastname= 'Ministrator'
    user.login_slug= 'Administrator'
    user.role_id= Role[:admin].id
    user.birthday= 25.years.ago.to_date
    user.address1= '1 Global Sports Way'
    user.city= 'Globalcity'
    user.phone= '301.555.1212'
    user.password= 'gsadmin123'
    user.password_confirmation= 'gsadmin123'
    user.save!
  end

  def self.down
    user = User.find_by_email('admin@globalsports.net')
    user.destroy if user
  end
  
end
