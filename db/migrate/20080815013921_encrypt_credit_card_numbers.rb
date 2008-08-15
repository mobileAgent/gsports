class EncryptCreditCardNumbers < ActiveRecord::Migration
  def self.up
    # Set up the cc number column for lucifer encryption
    remove_column :credit_cards, :number
    add_column :credit_cards, :number_encrypted, :binary
  end

  def self.down
    remove_column :credit_cards, :number_encrypted
    add_column :credit_cards, :number, :string
  end
end
