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
  
end