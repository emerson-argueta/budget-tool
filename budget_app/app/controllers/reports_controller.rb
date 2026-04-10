class ReportsController < ApplicationController
  def index
    @month = params[:month].present? ? Date.strptime(params[:month], "%Y-%m") : Date.today
    @budget = current_user.budget_for(@month)

    # Spending by category (current month)
    if @budget
      @spending_by_category = @budget.budget_categories
        .map { |cat| [cat.name, cat.spent.to_f] }
        .reject { |_, v| v.zero? }
        .sort_by { |_, v| -v }
        .to_h
    end

    # Monthly spending trend (last 6 months)
    @monthly_trend = build_monthly_trend

    # Net worth (sum of all account balances)
    @net_worth = build_net_worth

    # Top merchants (last 30 days, debit transactions)
    @top_merchants = build_top_merchants

    @month_label = @month.strftime("%B %Y")
  end

  private

  def build_monthly_trend
    6.downto(0).map do |i|
      m = Date.today.beginning_of_month - i.months
      budget = current_user.budget_for(m)
      spent = budget ? budget.total_spent.to_f : 0
      [m.strftime("%b %Y"), spent]
    end.to_h
  end

  def build_net_worth
    accounts = current_user.accounts
    assets = accounts.where(account_type: "depository").sum(:current_balance) || 0
    liabilities = accounts.where(account_type: "credit").sum(:current_balance) || 0
    { assets: assets, liabilities: liabilities, net: assets - liabilities }
  end

  def build_top_merchants
    current_user.transactions
      .where("date >= ?", 30.days.ago)
      .where("amount > 0")
      .group("COALESCE(transactions.merchant_name, transactions.name)")
      .sum(:amount)
      .sort_by { |_, v| -v }
      .first(10)
      .to_h
  end
end
