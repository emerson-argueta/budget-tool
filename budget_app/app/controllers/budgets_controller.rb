class BudgetsController < ApplicationController
  before_action :set_budget, only: [:show, :edit, :update, :copy_previous, :income_transactions]

  def index
    redirect_to budget_path(Date.today.strftime("%Y-%m"))
  end

  def show
    @groups = CategoryGroup.ordered.includes(
      budget_categories: { transactions: [] }
    )
    # Filter categories to only those belonging to this budget
    @categories_by_group = @groups.each_with_object({}) do |group, hash|
      hash[group] = @budget.budget_categories
                           .where(category_group: group)
                           .order(:name)
    end
    @month_options = month_options
  end

  def new
    @budget = current_user.budgets.new(month: Date.today.beginning_of_month)
  end

  def create
    @budget = current_user.budgets.new(budget_params)
    @budget.month = Date.strptime(params[:budget][:month], "%Y-%m").beginning_of_month rescue Date.today.beginning_of_month

    if params[:copy_from].present?
      source = Budget.find(params[:copy_from])
      copy_categories_from(source, @budget)
    end

    if @budget.save
      redirect_to budget_path(@budget), notice: "Budget created for #{@budget.month_label}."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def income_transactions
    @transactions = Transaction.income
      .joins(account: :plaid_item)
      .where(plaid_items: { user: current_user })
      .for_month(@budget.month)
      .includes(:account)
      .recent
    @budget_categories = @budget.budget_categories.order(:name)
  end

  def copy_previous
    source = current_user.budgets.find_by(month: @budget.month.prev_month)

    unless source
      redirect_to budget_path(@budget), alert: "No budget found for #{@budget.month.prev_month.strftime("%B %Y")}."
      return
    end

    copied = 0
    source.budget_categories.each do |cat|
      next if @budget.budget_categories.exists?(name: cat.name, category_group_id: cat.category_group_id)
      @budget.budget_categories.create!(
        name:              cat.name,
        planned_amount:    cat.planned_amount,
        emoji:             cat.emoji,
        category_group_id: cat.category_group_id
      )
      copied += 1
    end

    redirect_to budget_path(@budget), notice: "Copied #{copied} categor#{copied == 1 ? "y" : "ies"} from #{source.month_label}."
  end

  def update
    if @budget.update(budget_params)
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace("budget_summary", partial: "budgets/summary", locals: { budget: @budget }),
            turbo_stream.replace("flash", partial: "shared/flash", locals: { notice: "Income updated." })
          ]
        end
        format.html { redirect_to budget_path(@budget), notice: "Budget updated." }
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_budget
    month_param = params[:month] || Date.today.strftime("%Y-%m")
    @budget = Budget.find_by_month_param(month_param)

    unless @budget
      # Auto-create budget for the month
      date = Date.strptime(month_param, "%Y-%m") rescue Date.today
      @budget = current_user.budgets.create!(
        month: date.beginning_of_month,
        total_income: 0
      )
    end
  end

  def budget_params
    params.require(:budget).permit(:total_income)
  end

  def copy_categories_from(source, target)
    source.budget_categories.each do |cat|
      target.budget_categories.build(
        name: cat.name,
        planned_amount: cat.planned_amount,
        emoji: cat.emoji,
        category_group_id: cat.category_group_id
      )
    end
  end

  def month_options
    months = current_user.budgets.recent.limit(12).map { |b| [b.month_label, b.to_param] }
    # Ensure current and next month are present
    [
      [Date.today.next_month.strftime("%B %Y"), Date.today.next_month.strftime("%Y-%m")],
      [Date.today.strftime("%B %Y"), Date.today.strftime("%Y-%m")]
    ].each do |opt|
      months.unshift(opt) unless months.any? { |m| m[1] == opt[1] }
    end
    months.uniq.sort_by { |m| m[1] }.reverse
  end
end
