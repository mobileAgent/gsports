class BillingController < ApplicationController

  active_scaffold :user do |config|
    config.theme = :blue
    config.label = "Users"
    config.columns[:login].label = "login"

    config.list.columns[:login]
  end

  def index
  end

  def conditions_for_collection
    return ["1=1"]
  end

end
