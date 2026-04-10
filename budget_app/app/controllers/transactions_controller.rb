class TransactionsController < ApplicationController
  before_action :set_transaction, only: [:show, :update]
  before_action :set_accounts_and_categories, only: [:new, :create]

  def index
    scope = current_user.transactions.includes(:account, :budget_category)
    scope = apply_filters(scope)
    @pagy, @transactions = pagy(scope.recent, limit: 50)
    @accounts = current_user.accounts.order(:name)
    @budget_categories = current_month_budget_categories
    @budget_categories_by_month = budget_categories_by_month_for(@transactions)
    @current_filter = filter_params
  end

  def new
    @transaction = Transaction.new(date: Date.today)
  end

  def create
    account = params[:transaction][:account_id].present? ?
      current_user.accounts.find(params[:transaction][:account_id]) :
      current_user.cash_account

    raw_amount = params[:transaction][:amount].to_d
    is_income  = params[:transaction][:transaction_type] == "income"
    # DB convention: positive = expense, negative = income
    stored_amount = is_income ? -raw_amount.abs : raw_amount.abs

    @transaction = account.transactions.new(
      date:               params[:transaction][:date],
      name:               params[:transaction][:name],
      merchant_name:      params[:transaction][:merchant_name],
      amount:             stored_amount,
      is_income:          is_income,
      budget_category_id: is_income ? nil : params[:transaction][:budget_category_id],
      notes:              params[:transaction][:notes]
    )

    if @transaction.save
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace("flash",
            partial: "shared/flash",
            locals: { notice: "Transaction added." })
        end
        format.html { redirect_to transactions_path, notice: "Transaction added." }
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  def unassigned
    scope = current_user.transactions.unassigned.includes(:account)
    @pagy, @transactions = pagy(scope.recent, limit: 50)
    @budget_categories = current_month_budget_categories
    @budget_categories_by_month = budget_categories_by_month_for(@transactions)
  end

  def show
    @budget_categories = budget_categories_for_month(@transaction.date)
  end

  def update
    @budget_categories = budget_categories_for_month(@transaction.date)
    if @transaction.update(transaction_params)
      # Save merchant rule if requested
      if params[:save_rule] == "1" && @transaction.budget_category_id?
        save_merchant_rule(@transaction)
      end

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace("transaction_#{@transaction.id}",
              partial: "transactions/transaction",
              locals: { transaction: @transaction }),
            turbo_stream.replace("unassigned_count", partial: "shared/unassigned_count")
          ]
        end
        format.html { redirect_back(fallback_location: transactions_path, notice: "Transaction updated.") }
      end
    else
      render json: { error: @transaction.errors.full_messages.join(", ") }, status: :unprocessable_entity
    end
  end

  def bulk_assign
    ids = params[:transaction_ids] || []
    category_id = params[:budget_category_id]

    transactions = current_user.transactions.where(id: ids)
    transactions.update_all(budget_category_id: category_id)

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace("transactions_list",
          partial: "transactions/list",
          locals: { transactions: transactions.reload.includes(:account, :budget_category) })
      end
      format.html { redirect_to transactions_path, notice: "#{transactions.count} transactions assigned." }
    end
  end

  private

  def set_accounts_and_categories
    @accounts = current_user.accounts.order(:name)
    @budget_categories = current_month_budget_categories
  end

  def set_transaction
    @transaction = current_user.transactions.find(params[:id])
  end

  def transaction_params
    params.require(:transaction).permit(:budget_category_id, :notes, :is_income)
  end

  def apply_filters(scope)
    if params[:month].present?
      date = Date.strptime(params[:month], "%Y-%m") rescue Date.today
      scope = scope.for_month(date)
    end
    scope = scope.where(account_id: params[:account_id]) if params[:account_id].present?
    scope = scope.where(budget_category_id: params[:category_id]) if params[:category_id].present?
    if params[:q].present?
      q = "%#{params[:q]}%"
      scope = scope.where("transactions.name LIKE ? OR transactions.merchant_name LIKE ?", q, q)
    end
    scope = scope.unassigned if params[:unassigned] == "1"
    scope
  end

  def filter_params
    params.permit(:month, :account_id, :category_id, :q, :unassigned)
  end

  def budget_categories_for_month(date)
    budget = current_user.budgets.find_by(month: date.beginning_of_month)
    budget ||= current_user.current_budget || current_user.budgets.recent.first
    return BudgetCategory.none unless budget
    budget.budget_categories.includes(:category_group).order("category_groups.position, budget_categories.name")
  end

  def budget_categories_by_month_for(transactions)
    months = transactions.map { |t| t.date.beginning_of_month }.uniq
    months.index_with { |month| budget_categories_for_month(month) }
  end

  def current_month_budget_categories
    # Try current month first, fall back to most recent budget, then all
    budget = current_user.current_budget || current_user.budgets.recent.first
    if budget
      budget.budget_categories.includes(:category_group).order("category_groups.position, budget_categories.name")
    else
      BudgetCategory.joins(:budget).where(budgets: { user_id: current_user })
                    .includes(:category_group).order("category_groups.position, budget_categories.name")
    end
  end

  def save_merchant_rule(transaction)
    name = transaction.merchant_name.presence || transaction.name
    return if name.blank?
    current_user.merchant_rules.find_or_create_by(
      pattern: name,
      budget_category_id: transaction.budget_category_id
    )
  end
end
