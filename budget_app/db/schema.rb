# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_04_21_134302) do
  create_table "accounts", force: :cascade do |t|
    t.string "account_type"
    t.decimal "available_balance", precision: 10, scale: 2
    t.datetime "created_at", null: false
    t.decimal "current_balance", precision: 10, scale: 2
    t.string "mask"
    t.string "name"
    t.string "official_name"
    t.string "plaid_account_id", null: false
    t.integer "plaid_item_id", null: false
    t.string "subtype"
    t.datetime "updated_at", null: false
    t.index ["plaid_account_id"], name: "index_accounts_on_plaid_account_id", unique: true
    t.index ["plaid_item_id"], name: "index_accounts_on_plaid_item_id"
  end

  create_table "budget_categories", force: :cascade do |t|
    t.integer "budget_id", null: false
    t.integer "category_group_id", null: false
    t.datetime "created_at", null: false
    t.string "emoji"
    t.string "name", null: false
    t.decimal "planned_amount", precision: 10, scale: 2, default: "0.0", null: false
    t.datetime "updated_at", null: false
    t.index ["budget_id"], name: "index_budget_categories_on_budget_id"
    t.index ["category_group_id"], name: "index_budget_categories_on_category_group_id"
  end

  create_table "budgets", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "month", null: false
    t.decimal "total_income", precision: 10, scale: 2, default: "0.0", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["user_id", "month"], name: "index_budgets_on_user_id_and_month", unique: true
    t.index ["user_id"], name: "index_budgets_on_user_id"
  end

  create_table "category_groups", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.integer "position", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["position"], name: "index_category_groups_on_position"
  end

  create_table "merchant_rules", force: :cascade do |t|
    t.integer "budget_category_id", null: false
    t.datetime "created_at", null: false
    t.string "pattern"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["budget_category_id"], name: "index_merchant_rules_on_budget_category_id"
    t.index ["user_id"], name: "index_merchant_rules_on_user_id"
  end

  create_table "plaid_items", force: :cascade do |t|
    t.string "access_token"
    t.datetime "created_at", null: false
    t.string "cursor"
    t.string "institution_id"
    t.string "institution_name"
    t.string "item_id"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_plaid_items_on_user_id"
  end

  create_table "sinking_funds", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.decimal "current_amount", precision: 10, scale: 2, default: "0.0", null: false
    t.string "emoji"
    t.decimal "goal_amount", precision: 10, scale: 2, default: "0.0", null: false
    t.string "name", null: false
    t.text "notes"
    t.date "target_date"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_sinking_funds_on_user_id"
  end

  create_table "transactions", force: :cascade do |t|
    t.integer "account_id", null: false
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.integer "budget_category_id"
    t.datetime "created_at", null: false
    t.date "date", null: false
    t.boolean "is_income", default: false, null: false
    t.string "merchant_name"
    t.string "name"
    t.text "notes"
    t.boolean "pending", default: false
    t.string "plaid_category"
    t.string "plaid_transaction_id"
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_transactions_on_account_id"
    t.index ["budget_category_id"], name: "index_transactions_on_budget_category_id"
    t.index ["date"], name: "index_transactions_on_date"
    t.index ["is_income"], name: "index_transactions_on_is_income"
    t.index ["plaid_transaction_id"], name: "index_transactions_on_plaid_transaction_id", unique: true, where: "plaid_transaction_id IS NOT NULL"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.boolean "otp_required_for_login", default: false, null: false
    t.string "otp_secret"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "accounts", "plaid_items"
  add_foreign_key "budget_categories", "budgets"
  add_foreign_key "budget_categories", "category_groups"
  add_foreign_key "budgets", "users"
  add_foreign_key "merchant_rules", "budget_categories"
  add_foreign_key "merchant_rules", "users"
  add_foreign_key "plaid_items", "users"
  add_foreign_key "sinking_funds", "users"
  add_foreign_key "transactions", "accounts"
  add_foreign_key "transactions", "budget_categories"
end
