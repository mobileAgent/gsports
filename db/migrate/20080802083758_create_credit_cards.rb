class CreateCreditCards < ActiveRecord::Migration
  def self.up
    create_table :credit_cards do |t|
      t.string :first_name
      t.string :last_name
      t.string :number
      t.string :month
      t.string :year
      t.string :verification_value
      t.integer :membership_id
      t.timestamps
    end
  end

  def self.down
    drop_table :credit_cards
  end
end
