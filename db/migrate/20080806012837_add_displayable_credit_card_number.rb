class AddDisplayableCreditCardNumber < ActiveRecord::Migration
  def self.up
    add_column :credit_cards, :displayable_number, :string
  end

  def self.down
  end
end
