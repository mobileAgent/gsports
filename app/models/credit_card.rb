class CreditCard < ActiveRecord::Base
  belongs_to :user
  
  # Enable lucifer encryption on the number in the db
  # The db column is number_encrypted, and lucifer just
  # adds virtual attribute called number. The data in the db
  # is encrypted but we never need to worry about it
  encrypt_attributes :suffix=>'_encrypted', :key_file=>'lucifer.yml'

  # List cards expiring this month
  named_scope :expiring,
    :conditions => ["month = ? and year = ?",Time.now.month,Time.now.year]

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
  
  def expired?
    !expiration_date.nil? && expiration_date < Date.today
  end
  
  def self.from_active_merchant_cc(ccinfo)
    new(:first_name => ccinfo.first_name,
        :last_name => ccinfo.last_name,
        :number => ccinfo.number,
        :month => ccinfo.month,
        :year => ccinfo.year,
        :verification_value => ccinfo.verification_value,
        :displayable_number => ccinfo.number[(ccinfo.number.length - 4)..ccinfo.number.length])
  end
  
  def to_active_merchant_cc
    ActiveMerchant::Billing::CreditCard.new({
                             :first_name => first_name,
                             :last_name => last_name,
                             :number => number,
                             :month => month,
                             :year => year,
                             :verification_value => verification_value})

  end
  
  def equals?(other)
    (other != nil && other.first_name==first_name &&
        other.last_name==last_name
        other.number==number
        other.verification_value==verification_value
        other.month==month
        other.year==year)
  end
end
