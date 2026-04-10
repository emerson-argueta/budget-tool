class SinkingFundsController < ApplicationController
  before_action :set_fund, only: [:show, :edit, :update, :destroy, :deposit, :withdraw]

  def index
    @funds = current_user.sinking_funds.order(:name)
    @new_fund = current_user.sinking_funds.new
  end

  def show
  end

  def new
    @fund = current_user.sinking_funds.new
  end

  def create
    @fund = current_user.sinking_funds.new(fund_params)
    if @fund.save
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.prepend("sinking_funds_grid", partial: "sinking_funds/fund_card", locals: { fund: @fund }),
            turbo_stream.replace("new_fund_form", partial: "sinking_funds/new_fund_form", locals: { fund: current_user.sinking_funds.new })
          ]
        end
        format.html { redirect_to sinking_funds_path, notice: "Fund created." }
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @fund.update(fund_params)
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace("sinking_fund_#{@fund.id}",
            partial: "sinking_funds/fund_card", locals: { fund: @fund })
        end
        format.html { redirect_to sinking_funds_path, notice: "Fund updated." }
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @fund.destroy
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.remove("sinking_fund_#{@fund.id}") }
      format.html { redirect_to sinking_funds_path, notice: "Fund deleted." }
    end
  end

  def deposit
    amount = params[:amount].to_d
    if amount > 0
      @fund.update!(current_amount: @fund.current_amount + amount)
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace("sinking_fund_#{@fund.id}",
            partial: "sinking_funds/fund_card", locals: { fund: @fund })
        end
        format.html { redirect_to sinking_funds_path }
      end
    else
      redirect_to sinking_funds_path, alert: "Invalid amount."
    end
  end

  def withdraw
    amount = params[:amount].to_d
    if amount > 0 && amount <= @fund.current_amount
      @fund.update!(current_amount: @fund.current_amount - amount)
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace("sinking_fund_#{@fund.id}",
            partial: "sinking_funds/fund_card", locals: { fund: @fund })
        end
        format.html { redirect_to sinking_funds_path }
      end
    else
      redirect_to sinking_funds_path, alert: "Invalid amount."
    end
  end

  private

  def set_fund
    @fund = current_user.sinking_funds.find(params[:id])
  end

  def fund_params
    params.require(:sinking_fund).permit(:name, :goal_amount, :current_amount, :target_date, :emoji, :notes)
  end
end
