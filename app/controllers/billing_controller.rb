class BillingController < ApplicationController

  def index
    @memberships = Membership.find :all
  end
end
