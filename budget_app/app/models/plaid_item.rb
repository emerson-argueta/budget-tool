class PlaidItem < ApplicationRecord
  belongs_to :user
  has_many :accounts, dependent: :destroy
  has_many :transactions, through: :accounts

  validates :access_token, presence: true
  validates :item_id, presence: true, uniqueness: true
end
