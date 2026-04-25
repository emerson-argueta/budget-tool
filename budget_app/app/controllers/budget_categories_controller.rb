class BudgetCategoriesController < ApplicationController
  before_action :set_budget_category, only: [:edit, :update, :destroy, :update_amount, :transactions]
  before_action :set_budget, only: [:new, :create]

  def new
    @category = @budget.budget_categories.new
    @groups = CategoryGroup.ordered
  end

  def create
    @category = @budget.budget_categories.new(category_params)
    if @category.save
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace("group_#{@category.category_group_id}",
              partial: "budgets/category_group",
              locals: { group: @category.category_group, budget: @budget,
                        categories: @budget.budget_categories.where(category_group: @category.category_group).order(:name) }),
            turbo_stream.replace("budget_summary", partial: "budgets/summary", locals: { budget: @budget.reload })
          ]
        end
        format.html { redirect_to budget_path(@budget) }
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @category.update(category_params)
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace("budget_category_#{@category.id}",
              partial: "budgets/category_row",
              locals: { category: @category, budget: @category.budget }),
            turbo_stream.replace("budget_summary", partial: "budgets/summary", locals: { budget: @category.budget.reload })
          ]
        end
        format.html { redirect_to budget_path(@category.budget) }
      end
    else
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace("budget_category_#{@category.id}_form",
          partial: "budget_categories/form", locals: { category: @category }) }
        format.html { render :edit, status: :unprocessable_entity }
      end
    end
  end

  def update_amount
    if @category.update(planned_amount: params[:planned_amount])
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace("budget_category_#{@category.id}",
              partial: "budgets/category_row",
              locals: { category: @category, budget: @category.budget }),
            turbo_stream.replace("budget_summary", partial: "budgets/summary", locals: { budget: @category.budget.reload })
          ]
        end
        format.json { render json: { planned_amount: @category.planned_amount } }
      end
    else
      render json: { error: @category.errors.full_messages.join(", ") }, status: :unprocessable_entity
    end
  end

  def transactions
    @transactions = @category.transactions.for_month(@category.budget.month).recent
    @budget_categories = @category.budget.budget_categories.order(:name)
  end

  def destroy
    budget = @category.budget
    @category.destroy
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.remove("budget_category_#{@category.id}"),
          turbo_stream.replace("budget_summary", partial: "budgets/summary", locals: { budget: budget.reload })
        ]
      end
      format.html { redirect_to budget_path(budget) }
    end
  end

  private

  def set_budget_category
    @category = BudgetCategory.find(params[:id])
    authorize_budget!(@category.budget)
  end

  def set_budget
    @budget = Budget.find_by_month_param(params[:budget_month])
    redirect_to budgets_path, alert: "Budget not found." unless @budget
    authorize_budget!(@budget)
  end

  def authorize_budget!(budget)
    unless budget.user == current_user
      redirect_to authenticated_root_path, alert: "Not authorized."
    end
  end

  def category_params
    params.require(:budget_category).permit(:name, :planned_amount, :emoji, :category_group_id)
  end
end
