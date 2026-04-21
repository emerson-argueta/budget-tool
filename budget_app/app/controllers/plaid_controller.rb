class PlaidController < ApplicationController
  def link
    @exchange_url = plaid_exchange_token_path
    @return_url   = accounts_path
    @oauth_redirect = params[:oauth_state_id].present?

    if @oauth_redirect && session[:plaid_link_token].present?
      @link_token = session[:plaid_link_token]
    else
      redirect_uri = ENV["PLAID_REDIRECT_URI"].presence
      @link_token = PlaidService.new.create_link_token(current_user.id, redirect_uri: redirect_uri).link_token
      session[:plaid_link_token] = @link_token
    end
  rescue Plaid::ApiError => e
    redirect_to accounts_path, alert: "Plaid error: #{e.message}"
  end

  def exchange_token
    public_token = params.require(:public_token)
    metadata = params.permit(metadata: {}).dig(:metadata) || {}

    service = PlaidService.new
    exchange = service.exchange_public_token(public_token)

    # Fetch institution info
    item_response = service.get_item(exchange.access_token)
    institution_id = item_response.item.institution_id
    institution_name = begin
      inst_response = service.get_institution(institution_id)
      inst_response.institution.name
    rescue
      metadata["institution"]&.dig("name") || "Unknown"
    end

    plaid_item = current_user.plaid_items.create!(
      access_token: exchange.access_token,
      item_id: exchange.item_id,
      institution_id: institution_id,
      institution_name: institution_name
    )

    # Sync accounts
    accounts_response = service.get_accounts(exchange.access_token)
    accounts_response.accounts.each do |plaid_account|
      plaid_item.accounts.create!(
        plaid_account_id: plaid_account.account_id,
        name: plaid_account.name,
        official_name: plaid_account.official_name,
        account_type: plaid_account.type,
        subtype: plaid_account.subtype,
        current_balance: plaid_account.balances.current,
        available_balance: plaid_account.balances.available,
        mask: plaid_account.mask
      )
    end

    # Kick off initial sync
    SyncTransactionsJob.perform_later(plaid_item.id)

    session.delete(:plaid_link_token)
    render json: { success: true, institution: institution_name }
  rescue Plaid::ApiError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def sync
    current_user.plaid_items.each do |item|
      SyncTransactionsJob.perform_later(item.id)
    end
    redirect_to accounts_path, notice: "Sync started for #{current_user.plaid_items.count} connected bank(s)."
  end

  def webhook
    # Acknowledge receipt — handle async in a job if needed
    head :ok
  end
end
