class AdSlot

  # There are two header slots for logos or ads.
  # Slot 1 has the league logo associated with the 
  # users team. If no logo, an ad is supplied.
  # Slot 2 has the team logo for the users team.
  # If the team has no logo, pull an ad
  # This class just helps sort out the mess

  def self.header_slot1_is_logo(u)
    return u.league && u.league.avatar_id?
  end

  def self.header_slot2_is_logo(u)
    return false if u.league_staff?
    return u.team && u.team.avatar_id?
  end

  def self.header_slot1_img_tag(u)
    "<img src='#{u.league.avatar.public_filename}' title='#{u.league_name}' alt='#{u.league_name}'/>"
  end    

  def self.header_slot2_img_tag(u)
    "<img src='#{u.team.avatar.public_filename}' title='#{u.team_name}' alt='#{u.team_name}'/>"
  end
  
end
