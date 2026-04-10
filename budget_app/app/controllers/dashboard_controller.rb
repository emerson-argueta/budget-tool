class DashboardController < ApplicationController
  def show
    @budget = current_user.current_budget
    @month_label = Date.today.strftime("%B %Y")

    if @budget
      @total_income = @budget.total_income
      @total_spent = @budget.total_spent
      @remaining = @total_income - @total_spent
      @to_assign = @budget.to_assign
      @over_budget_categories = @budget.budget_categories.select(&:over_budget?)
      @categories = @budget.budget_categories.includes(:category_group).order("category_groups.position, budget_categories.name")
    end

    @recent_transactions = current_user.transactions.includes(:account, :budget_category).recent.limit(10)
    @accounts = current_user.accounts.includes(:plaid_item).order(:name)
    @sinking_funds = current_user.sinking_funds.order(:name)
    @unassigned_count = current_user.transactions.unassigned.count
  end
end
