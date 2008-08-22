namespace :users do
  desc "Create users from the xml representation off the pilot site"
  task :load_pilot_users => :environment do
    file = ARGV[1]
    if file.nil?
      puts "Need a file name"
      exit
    end
    doc = Hpricot.parse(File.read(file))
    user_elements = doc.search('//user')
    count = 0
    for user in user_elements
      u = User.new()
      u.email= user.search('//email_address').text
      next if(u.email.nil? || u.email.length == 0)
      if (User.find_by_email(u.email))
        puts ("Skipping #{u.email} already exists");
        next
      end
      u.firstname= user.search('//First_Name').text
      u.lastname= user.search('//Last_Name').text
      u.firstname= u.email.gsub(/@.*/,'') if (u.firstname.nil? || u.firstname.length == 0)
      u.lastname= u.email.gsub(/@.*/,'') if (u.lastname.nil? || u.lastname.length == 0)
      u.address1= user.search('//Address').text
      u.address1 = 'not provided' if(u.address1.nil? || u.address1.length == 0)
      u.address2= user.search('//Address_2').text
      u.city= user.search('//City').text
      u.city= 'Notprovided' if(u.city.nil? || u.city.length == 0)
      u.zip= user.search('//Zip_Code').text
      u.enabled = true
      u.activated_at = Time.now
      state_name = user.search('//State').text
      if state_name
        state = State.find_by_name(state_name.upcase)
        if (state)
          u.state_id = state.id
        else
          u.state_id = 13 # MD
        end
      else
        u.state_id = 13 # MD
      end
      u.role_id= Role[:member].id
      u.phone="not provided"
      u.team_id = 1
      u.league_id = 1
      u.password= u.firstname[0..5] + "123456"
      u.password_confirmation= u.firstname[0..5] + "123456"
      u.login= "gspilot-#{Time.now.to_i}#{rand(100)}"
      u.birthday = 20.years.ago
      puts "#{u.full_name} => #{u.valid?}"
      u.save!
      count += 1
    end
  end
end
