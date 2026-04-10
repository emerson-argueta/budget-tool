class CreatePlaidItems < ActiveRecord::Migration[8.1]
  def change
    create_table :plaid_items do |t|
      t.string :access_token
      t.string :item_id
      t.string :institution_name
      t.string :institution_id
      t.string :cursor
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
