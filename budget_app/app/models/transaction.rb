class Transaction < ApplicationRecord
  belongs_to :account
  belongs_to :budget_category, optional: true

  validates :amount, presence: true
  validates :date, presence: true

  scope :unassigned, -> { where(budget_category_id: nil, is_income: false) }
  scope :assigned, -> { where.not(budget_category_id: nil) }
  scope :income, -> { where(is_income: true) }
  scope :for_month, ->(month) { where(date: month.beginning_of_month..month.end_of_month) }
  scope :recent, -> { order(date: :desc) }
  scope :not_pending, -> { where(pending: false) }

  before_save :clear_category_if_income

  def display_name
    merchant_name.presence || name
  end

  def assigned?
    budget_category_id.present?
  end

  private

  def clear_category_if_income
    self.budget_category_id = nil if is_income?
  end

  # Plaid returns positive for debits (spending), negative for credits (income)
  # We store amounts as positive = spending, negative = income/refunds
  def self.from_plaid(plaid_txn, account)
    find_or_initialize_by(plaid_transaction_id: plaid_txn.transaction_id).tap do |t|
      t.account = account
      t.amount = plaid_txn.amount  # Plaid: positive = debit, negative = credit
      t.date = plaid_txn.date
      t.name = plaid_txn.name
      t.merchant_name = plaid_txn.merchant_name
      t.pending = plaid_txn.pending
      t.plaid_category = plaid_txn.personal_finance_category&.primary
    end
  end
end
