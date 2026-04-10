class AddIsIncomeToTransactions < ActiveRecord::Migration[8.1]
  def change
    add_column :transactions, :is_income, :boolean, default: false, null: false
    add_index :transactions, :is_income
  end
end
