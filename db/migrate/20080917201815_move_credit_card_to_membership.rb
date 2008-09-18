class MoveCreditCardToMembership < ActiveRecord::Migration
  def self.up
    add_column :memberships, :credit_card_id, :integer, :size => 11
    add_column :membership_billing_histories, :credit_card_id, :integer, :size => 11
    execute "update memberships set credit_card_id=(select cc.id from credit_cards cc where cc.membership_id=memberships.id order by created_at desc limit 1) where credit_card_id is null and billing_method='cc'"
    execute "update membership_billing_histories set credit_card_id=(select cc.id from credit_cards cc where cc.membership_id=membership_billing_histories.membership_id order by created_at desc limit 1) where credit_card_id is null and payment_method='cc'"
    

    add_column :credit_cards, :user_id, :integer, :size => 11
    execute "update credit_cards set user_id=(select s.user_id from subscriptions s where s.membership_id=credit_cards.membership_id limit 1)"
    remove_column :credit_cards, :membership_id
  end

  def self.down
    add_column :credit_cards, :membership_id, :integer, :size => 11
    execute "update credit_cards set membership_id=(select m.credit_card_id from memberships m where m.credit_card_id=credit_cards.id)"
    
    remove_column :memberships, :credit_card_id
    remove_column :membership_billing_histories, :credit_card_id
  end
end
