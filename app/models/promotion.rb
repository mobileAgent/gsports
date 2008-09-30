class Promotion < ActiveRecord::Base
   # Save the redcloth html on write
  before_save :generate_html
  # make all promo codes uppercase for case-insensitive uniqueness
  before_validation :uppercase_promo_code

  validates_presence_of :promo_code
  validates_uniqueness_of :promo_code
  belongs_to :subscription_plan
  
  named_scope :active, :conditions => { :enabled => true }  
  
  def initialize(params = nil)
    super
    # initialize enabledS
    self.enabled = true unless self.enabled
  end

  def enabled?
    enabled
  end
  
  def reusable?
    reusable
  end

  protected
  def generate_html
    if self.content && !self.content.blank?
      self.html_content = RedCloth.new(self.content).to_html
    end
  end
  
  def uppercase_promo_code
    if self.promo_code && !self.promo_code.blank?
      self.promo_code = self.promo_code.upcase
    end
  end
  
end
