class CreateAccounts < ActiveRecord::Migration
  def change
    create_table :accounts do |t|
      t.integer :provider_account_id
      t.string :login_key

      t.timestamps null: false
    end
    
    add_index :accounts, :provider_account_id, :unique => true
  end
end
