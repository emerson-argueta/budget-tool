class MerchantRule < ApplicationRecord
  belongs_to :budget_category
  belongs_to :user

  validates :pattern, presence: true

  def matches?(transaction_name)
    transaction_name.downcase.include?(pattern.downcase)
  end
end
