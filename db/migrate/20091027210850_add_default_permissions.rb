class AddDefaultPermissions < ActiveRecord::Migration
  def self.up
    admin_perms= [
      Permission::EDIT_TEAM_PAGE, 
      Permission::MANAGE_CHANNELS,
      Permission::MANAGE_GROUPS, 
      Permission::CREATE_STAFF, 
      Permission::UPLOAD
    ]
  
    User.find(:all, :conditions=>['role_id in (?)', [Role[:team], Role[:league]] ]).each() { |user|
      admin_perms.each() { |permission|
        begin
          scope = user.team_staff? ? user.team : user.league
          next if scope.nil?
          Permission.grant(user, permission, scope)
        rescue Exception=>e
          puts "error granting permission for user:#{user.id}. #{e.message}"
        end
      }
    }
  
    staff_perms = [
      Permission::EDIT_TEAM_PAGE, 
      Permission::MANAGE_CHANNELS,
      Permission::MANAGE_GROUPS, 
      Permission::UPLOAD
    ]
  
    User.find(:all, :conditions=>['role_id in (?)', [Role[:team_staff], Role[:league_staff]] ]).each() { |user|
      staff_perms.each() { |permission|
        begin
          scope = user.team_staff? ? user.team : user.league
          next if scope.nil?
          Permission.grant(user, permission, scope)
        rescue Exception=>e
          puts "error granting permission for user:#{user.id}. #{e.message}"
        end
      }
    }
  end

  def self.down
  end
end
