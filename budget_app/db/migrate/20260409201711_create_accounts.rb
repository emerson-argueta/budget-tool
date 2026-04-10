class CreateAccounts < ActiveRecord::Migration[8.1]
  def change
    create_table :accounts do |t|
      t.string :plaid_account_id, null: false
      t.string :name
      t.string :official_name
      t.string :account_type
      t.string :subtype
      t.decimal :current_balance, precision: 10, scale: 2
      t.decimal :available_balance, precision: 10, scale: 2
      t.string :mask
      t.references :plaid_item, null: false, foreign_key: true

      t.timestamps
    end
    add_index :accounts, :plaid_account_id, unique: true
  end
end
