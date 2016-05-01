class ChangeAccounts < ActiveRecord::Migration
  def change
    remove_column :accounts, :provider_account_id, :integer
    remove_column :accounts, :login_key, :string
  end
end
