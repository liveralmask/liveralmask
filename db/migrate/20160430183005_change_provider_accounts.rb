class ChangeProviderAccounts < ActiveRecord::Migration
  def change
    remove_column :provider_accounts, :uid, :string
    remove_column :provider_accounts, :name, :string
    remove_column :provider_accounts, :icon, :string
    remove_column :provider_accounts, :access_token, :text
    remove_column :provider_accounts, :account_id, :integer
    
    add_column :provider_accounts, :uid, :string, :null => false
    add_column :provider_accounts, :info, :text, :null => false
    add_column :provider_accounts, :access_token, :text, :null => false
    add_column :provider_accounts, :account_id, :integer, :null => false
    add_column :provider_accounts, :login_key, :string, :null => false
  end
end
