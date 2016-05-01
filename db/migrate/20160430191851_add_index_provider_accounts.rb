class AddIndexProviderAccounts < ActiveRecord::Migration
  def change
    add_index :provider_accounts, :uid, :unique => true
    add_index :provider_accounts, :account_id
    add_index :provider_accounts, :login_key, :unique => true
  end
end
