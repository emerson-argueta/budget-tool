class AccountsController < ApplicationController
  def index
    @plaid_items = current_user.plaid_items
                               .where.not(item_id: "manual_#{current_user.id}")
                               .includes(:accounts)
                               .order(:institution_name)
    @cash_account = current_user.plaid_items
                                .find_by(item_id: "manual_#{current_user.id}")
                                &.accounts&.first
  end

  def show
    @account = current_user.accounts.find(params[:id])
    @pagy, @transactions = pagy(@account.transactions.recent, limit: 50)
  end

  def clear_cash
    cash = current_user.cash_account
    count = cash.transactions.count
    cash.transactions.destroy_all
    redirect_to accounts_path, notice: "Deleted #{count} manual transaction#{"s" if count != 1}."
  end
end
