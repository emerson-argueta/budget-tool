class AccountsController < ApplicationController
  def index
    @plaid_items = current_user.plaid_items.includes(:accounts).order(:institution_name)
    @accounts = current_user.accounts.includes(:plaid_item).order(:name)
  end

  def show
    @account = current_user.accounts.find(params[:id])
    @pagy, @transactions = pagy(@account.transactions.recent, limit: 50)
  end
end
