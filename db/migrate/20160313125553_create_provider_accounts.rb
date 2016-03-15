class CreateProviderAccounts < ActiveRecord::Migration
  def change
    create_table :provider_accounts do |t|
      t.string :uid
      t.string :name
      t.string :icon
      t.text :access_token
      t.integer :account_id

      t.timestamps null: false
    end
    
    add_index :provider_accounts, :uid, :unique => true
  end
end
