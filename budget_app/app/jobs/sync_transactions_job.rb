class SyncTransactionsJob < ApplicationJob
  queue_as :default

  def perform(plaid_item_id)
    plaid_item = PlaidItem.find(plaid_item_id)
    service = PlaidService.new

    # Sync all pages of transactions
    cursor = plaid_item.cursor
    loop do
      response = service.sync_transactions(plaid_item.access_token, cursor: cursor)

      upsert_transactions(response.added + response.modified, plaid_item)
      remove_transactions(response.removed)

      cursor = response.next_cursor
      break unless response.has_more
    end

    plaid_item.update!(cursor: cursor)

    # Sync account balances
    sync_balances(plaid_item, service)

    # Auto-categorize new transactions
    uncategorized = plaid_item.transactions.unassigned.recent.limit(50)
    TransactionCategorizer.new(plaid_item.user).categorize_all(uncategorized)
  rescue Plaid::ApiError => e
    Rails.logger.error "Plaid sync error for item #{plaid_item_id}: #{e.message}"
    raise
  end

  private

  def upsert_transactions(plaid_txns, plaid_item)
    plaid_txns.each do |plaid_txn|
      account = plaid_item.accounts.find_by!(plaid_account_id: plaid_txn.account_id)
      txn = Transaction.from_plaid(plaid_txn, account)
      txn.save!
    end
  end

  def remove_transactions(removed)
    ids = removed.map(&:transaction_id)
    Transaction.where(plaid_transaction_id: ids).destroy_all
  end

  def sync_balances(plaid_item, service)
    response = service.get_accounts(plaid_item.access_token)
    response.accounts.each do |plaid_account|
      account = plaid_item.accounts.find_by(plaid_account_id: plaid_account.account_id)
      next unless account
      account.update!(
        current_balance: plaid_account.balances.current,
        available_balance: plaid_account.balances.available
      )
    end
  end
end
