class CreateMerchantRules < ActiveRecord::Migration[8.1]
  def change
    create_table :merchant_rules do |t|
      t.string :pattern
      t.references :budget_category, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
