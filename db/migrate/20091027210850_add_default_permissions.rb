class AddDefaultPermissions < ActiveRecord::Migration
  def self.up
    User.find(:all, :conditions=>['role_id in (?)', [Role[:team], Role[:league], Role[:team_staff], Role[:league_staff]] ]).each() { |user|
      Permission.staff_permission_list.each() { |permission, name|
        begin
          scope = user.team_staff? ? user.team : user.league
          next if scope.nil?
          Permission.grant(user, permission, scope)
        rescue Exception=>e
          puts "error granting permission for user:#{user}. #{e.message}"
        end
      }
    }
  end

  def self.down
  end
end
