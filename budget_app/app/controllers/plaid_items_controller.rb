class PlaidItemsController < ApplicationController
  before_action :set_plaid_item

  def destroy
    account_count = @plaid_item.accounts.count
    tx_count = @plaid_item.accounts.sum { |a| a.transactions.count }

    @plaid_item.destroy

    redirect_to accounts_path,
      notice: "Disconnected #{@plaid_item.institution_name}. Deleted #{account_count} account#{"s" if account_count != 1} and #{tx_count} transaction#{"s" if tx_count != 1}."
  end

  private

  def set_plaid_item
    @plaid_item = current_user.plaid_items
                              .where.not(item_id: "manual_#{current_user.id}")
                              .find(params[:id])
  end
end
