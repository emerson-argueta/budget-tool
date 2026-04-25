class Transaction < ApplicationRecord
  belongs_to :account
  belongs_to :budget_category, optional: true

  validates :amount, presence: true
  validates :date, presence: true

  default_scope { where(deleted_at: nil) }

  scope :unassigned, -> { where(budget_category_id: nil, is_income: false, untracked: false) }
  scope :assigned, -> { where.not(budget_category_id: nil) }
  scope :income, -> { where(is_income: true) }
  scope :untracked, -> { where(untracked: true) }
  scope :for_month, ->(month) { where(date: month.beginning_of_month..month.end_of_month) }
  scope :recent, -> { order(date: :desc) }
  scope :not_pending, -> { where(pending: false) }

  before_save :clear_category_if_income
  before_save :clear_if_untracked

  def display_name
    merchant_name.presence || name
  end

  def assigned?
    budget_category_id.present?
  end

  def manual?
    plaid_transaction_id.nil?
  end

  def soft_delete!
    update_columns(deleted_at: Time.current, budget_category_id: nil)
  end

  private

  def clear_category_if_income
    self.budget_category_id = nil if is_income?
  end

  def clear_if_untracked
    if untracked?
      self.budget_category_id = nil
      self.is_income = false
    end
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
