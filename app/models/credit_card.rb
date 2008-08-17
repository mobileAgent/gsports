class CreditCard < ActiveRecord::Base
  belongs_to :membership
  # Enable lucifer encryption on the number in the db
  # The db column is number_encrypted, and lucifer just
  # adds virtual attribute called number. The data in the db
  # is encrypted but we never need to worry about it
  encrypt_attributes :suffix=>'_encrypted', :key_file=>'lucifer.yml'


  def expiration_date=(date)
    self.month=date.month
    self.year=date.year
  end

  def expiration_date
    if (self.year && self.month)
      Date.new(self.year.to_i,self.month.to_i,-1);
    else
      nil
    end
  end
  
end
