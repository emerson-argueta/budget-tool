class CreateSinkingFunds < ActiveRecord::Migration[8.1]
  def change
    create_table :sinking_funds do |t|
      t.string :name, null: false
      t.decimal :goal_amount, precision: 10, scale: 2, null: false, default: 0
      t.decimal :current_amount, precision: 10, scale: 2, null: false, default: 0
      t.date :target_date
      t.string :emoji
      t.text :notes
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
