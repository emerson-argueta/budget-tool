class BudgetCategory < ApplicationRecord
  belongs_to :budget
  belongs_to :category_group

  has_many :transactions, dependent: :nullify

  validates :name, presence: true
  validates :planned_amount, numericality: { greater_than_or_equal_to: 0 }

  def spent
    transactions.sum(:amount)
  end

  def remaining
    planned_amount - spent
  end

  def over_budget?
    remaining.negative?
  end

  def percent_spent
    return 0 if planned_amount.zero?
    [(spent / planned_amount * 100).round, 100].min
  end
end
