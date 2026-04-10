class Budget < ApplicationRecord
  belongs_to :user
  has_many :budget_categories, dependent: :destroy
  has_many :transactions, through: :budget_categories

  validates :month, presence: true, uniqueness: { scope: :user_id }
  validates :total_income, numericality: { greater_than_or_equal_to: 0 }

  before_save :normalize_month

  scope :recent, -> { order(month: :desc) }

  def total_assigned
    budget_categories.sum(:planned_amount)
  end

  # Income tagged transactions for this budget month
  def transaction_income
    Transaction.income
               .joins(account: :plaid_item)
               .where(plaid_items: { user: user })
               .for_month(month)
               .sum("ABS(amount)")
  end

  # total_income (manual) + transaction income
  def effective_income
    total_income + transaction_income
  end

  def to_assign
    effective_income - total_assigned
  end

  def total_spent
    transactions.sum(:amount)
  end

  def month_label
    month.strftime("%B %Y")
  end

  def to_param
    month.strftime("%Y-%m")
  end

  def self.find_by_month_param(param)
    date = Date.strptime(param, "%Y-%m")
    find_by(month: date.beginning_of_month)
  rescue Date::Error
    nil
  end

  private

  def normalize_month
    self.month = month.beginning_of_month if month
  end
end
