class CreditCard < ActiveRecord::Base
  belongs_to :membership


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
