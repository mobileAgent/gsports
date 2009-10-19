class Staff < User
  def user
    User.find(id)
  end
end
