class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  def totp
    ROTP::TOTP.new(otp_secret, issuer: "Budget App")
  end

  def otp_provisioning_uri
    totp.provisioning_uri(email)
  end

  def verify_otp(code)
    totp.verify(code.to_s.strip, drift_behind: 30, drift_ahead: 30)
  end

  def generate_otp_secret!
    update!(otp_secret: ROTP::Base32.random)
  end

  has_many :plaid_items, dependent: :destroy
  has_many :accounts, through: :plaid_items
  has_many :transactions, through: :accounts
  has_many :budgets, dependent: :destroy
  has_many :sinking_funds, dependent: :destroy
  has_many :merchant_rules, dependent: :destroy

  def cash_account
    cash_item = plaid_items.find_or_create_by(item_id: "manual_#{id}") do |item|
      item.institution_name = "Manual"
      item.institution_id   = "manual"
      item.access_token     = "manual_#{id}"
    end
    cash_item.accounts.find_or_create_by(plaid_account_id: "cash_#{id}") do |acct|
      acct.name         = "Cash"
      acct.account_type = "cash"
      acct.subtype      = "cash"
    end
  end

  def current_budget
    budgets.find_by(month: Date.today.beginning_of_month)
  end

  def budget_for(month)
    budgets.find_by(month: month.beginning_of_month)
  end
end
