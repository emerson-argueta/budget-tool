class CreateBudgets < ActiveRecord::Migration[8.1]
  def change
    create_table :budgets do |t|
      t.date :month, null: false
      t.decimal :total_income, precision: 10, scale: 2, null: false, default: 0
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
    add_index :budgets, [:user_id, :month], unique: true
  end
end
