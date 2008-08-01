module UsersHelper
  
  def requested_role_name()
    id = @requested_role.to_i
    begin
      @role = Role[id]
      if(@role)
        return @role.name();
      end
    rescue
    end

    "Player/Fan"
  end

  def random_greeting(user)
    greetings = ['Hello', 'Hola', 'Hi ', 'Yo', 'Welcome back,', 'Greetings',
        'Wassup', 'Aloha', 'Halloo']
    "#{greetings.sort_by {rand}.first} #{user.full_name}!"
  end
  
  
end
