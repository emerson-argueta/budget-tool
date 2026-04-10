class Account < ApplicationRecord
  belongs_to :plaid_item
  has_many :transactions, dependent: :destroy
  has_one :user, through: :plaid_item

  validates :plaid_account_id, presence: true, uniqueness: true

  scope :depository, -> { where(account_type: "depository") }
  scope :credit, -> { where(account_type: "credit") }

  def display_name
    mask.present? ? "#{name} ···#{mask}" : name
  end

  def institution_name
    plaid_item.institution_name
  end
end
