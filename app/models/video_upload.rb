

module VideoUpload


  def game_date_string
    if game_date.nil?
      game_date_str || ''
    elsif ignore_game_month
      game_date.strftime("%Y")
    elsif ignore_game_day
      game_date.strftime("%Y-%m")
    else
      game_date.to_s(:game_date)
    end
  end

  def human_game_date_string
    if game_date.nil?
      game_date_str || ''
    elsif ignore_game_month
      game_date.strftime("%Y")
    elsif ignore_game_day
      game_date.strftime("%B, %Y")
    else
      game_date.to_s(:readable)
    end
  end
  
  
  def push_me()

    self.video_status= Vidavee.PUSHING
    self.save!

    vidavee = Vidavee.find(:first)
    login = vidavee.login
    raise Exception.new( "Cannot log into vidavee back end" ) if login.nil?

    dockey = vidavee.push_video login, self, self.uploaded_file_path

    dockey

  end
  


end


