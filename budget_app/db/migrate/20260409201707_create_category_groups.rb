class CreateCategoryGroups < ActiveRecord::Migration[8.1]
  def change
    create_table :category_groups do |t|
      t.string :name, null: false
      t.integer :position, null: false, default: 0

      t.timestamps
    end
    add_index :category_groups, :position
  end
end
