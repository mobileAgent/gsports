class AddInviteSentToRosterEntry < ActiveRecord::Migration
  def self.up
    add_column :roster_entries, :invitation_sent, :boolean
  end

  def self.down
    remove_column :roster_entries, :invitation_sent
  end
end
