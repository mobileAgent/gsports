class AddTeamLeagueAvatar < ActiveRecord::Migration
  def self.up
    remove_column :teams, :logo_uri
    remove_column :leagues, :logo_uri
    add_column :teams, :avatar_id, :integer
    add_column :leagues, :avatar_id, :integer

    #puts "Creating the default team and league logo"
    #src_photo = "#{RAILS_ROOT}/public/images/gs_header_logo.png"
    #admin_user = User.find_by_email(ADMIN_EMAIL)
    #gs_logo = Photo.create(:name=>'Global Sports',:description=>'Global Sports',:content_type=>'image/png', :filename => src_photo)
    #gs_logo.user= admin_user
    #gs_logo.size= File.size(src_photo)
    #gs_logo.save!
    #dst_photo = "#{RAILS_ROOT}/public/photos/0000/"
    #dst_photo << sprintf("%04d",gs_logo.id)
    #File.makedirs dst_photo
    #dst_photo << "/gs_header_logo.png"
    #File.copy src_photo, dst_photo
    
    #puts "Ensure all teams have an avatar id"
    #Team.find(:all, :conditions => 'avatar_id IS NULL').each do |t|
    #  t.avatar= gs_logo
    #  t.save!
    #end
    
    #puts "Ensure all leagues have an avatar id"
    #League.find(:all, :conditions => 'avatar_id IS NULL').each do |l|
    #  l.avatar= gs_logo
    #  l.save!
    #end
    puts "Ensure all teams have a league"
    execute "update teams set league_id = 1 where league_id is null"
    #Team.find(:all, :conditions => 'league_id IS NULL').each do |t|
    #  t.update_attributes({:league_id => admin_user.league.id})
    #end

    puts "Ensure all users have a team"
    execute "update users set team_id = 1 where team_id is null"
    #User.find(:all, :conditions => 'team_id IS NULL').each do |u|
    #  u.update_attributes({:team_id => admin_user.team_id})
    #end
  end

  def self.down
    remove_column :teams, :avatar_id
    remove_column :leagues, :avatar_id
    add_column :teams, :logo_uri, :string
    add_column :leagues, :logo_uri, :string
  end
end
