class CreateTransactions < ActiveRecord::Migration[8.1]
  def change
    create_table :transactions do |t|
      t.string :plaid_transaction_id
      t.decimal :amount, precision: 10, scale: 2, null: false
      t.date :date, null: false
      t.string :name
      t.string :merchant_name
      t.boolean :pending, default: false
      t.string :plaid_category
      t.text :notes
      t.references :account, null: false, foreign_key: true
      t.references :budget_category, null: true, foreign_key: true

      t.timestamps
    end
    add_index :transactions, :plaid_transaction_id, unique: true, where: "plaid_transaction_id IS NOT NULL"
    add_index :transactions, :date
  end
end
