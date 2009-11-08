class CreatePermissions < ActiveRecord::Migration

  def self.up

    create_table :permissions do |t|

      t.string   :blessed_type
      t.integer  :blessed_id

      t.string   :role,       :limit => 30

      t.string   :scope_type
      t.integer  :scope_id

    end

    add_index(:permissions, [ :blessed_type, :blessed_id ])
    add_index(:permissions, [ :scope_type, :scope_id ])

  end

  def self.down
    drop_table :permissions
  end



end
