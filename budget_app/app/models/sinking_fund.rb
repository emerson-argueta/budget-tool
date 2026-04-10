class SinkingFund < ApplicationRecord
  belongs_to :user

  validates :name, presence: true
  validates :goal_amount, numericality: { greater_than: 0 }
  validates :current_amount, numericality: { greater_than_or_equal_to: 0 }

  def percent_complete
    return 100 if goal_amount.zero?
    [(current_amount / goal_amount * 100).round, 100].min
  end

  def remaining
    [goal_amount - current_amount, 0].max
  end

  def funded?
    current_amount >= goal_amount
  end

  def months_remaining
    return nil unless target_date
    months = ((target_date.year - Date.today.year) * 12) + (target_date.month - Date.today.month)
    [months, 0].max
  end

  def monthly_needed
    return 0 unless target_date && months_remaining&.positive?
    (remaining / months_remaining).ceil(2)
  end
end
