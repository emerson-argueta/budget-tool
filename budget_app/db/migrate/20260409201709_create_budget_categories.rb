class CreateBudgetCategories < ActiveRecord::Migration[8.1]
  def change
    create_table :budget_categories do |t|
      t.string :name, null: false
      t.decimal :planned_amount, precision: 10, scale: 2, null: false, default: 0
      t.string :emoji
      t.references :budget, null: false, foreign_key: true
      t.references :category_group, null: false, foreign_key: true

      t.timestamps
    end
  end
end
