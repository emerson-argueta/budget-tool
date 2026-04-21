class PlaidService
  def initialize
    configuration = Plaid::Configuration.new
    configuration.server_index = Plaid::Configuration::Environment[plaid_env]
    configuration.api_key["PLAID-CLIENT-ID"] = ENV.fetch("PLAID_CLIENT_ID")
    configuration.api_key["PLAID-SECRET"] = ENV.fetch("PLAID_SECRET")
    @client = Plaid::PlaidApi.new(Plaid::ApiClient.new(configuration))
  end

  def create_link_token(user_id, redirect_uri: nil)
    params = {
      user: Plaid::LinkTokenCreateRequestUser.new(client_user_id: user_id.to_s),
      client_name: "Budget App",
      products: ["transactions"],
      country_codes: ["US"],
      language: "en"
    }
    params[:redirect_uri] = redirect_uri if redirect_uri.present?
    @client.link_token_create(Plaid::LinkTokenCreateRequest.new(**params))
  end

  def exchange_public_token(public_token)
    request = Plaid::ItemPublicTokenExchangeRequest.new(public_token: public_token)
    @client.item_public_token_exchange(request)
  end

  def get_item(access_token)
    request = Plaid::ItemGetRequest.new(access_token: access_token)
    @client.item_get(request)
  end

  def get_accounts(access_token)
    request = Plaid::AccountsGetRequest.new(access_token: access_token)
    @client.accounts_get(request)
  end

  def get_institution(institution_id)
    request = Plaid::InstitutionsGetByIdRequest.new(
      institution_id: institution_id,
      country_codes: ["US"]
    )
    @client.institutions_get_by_id(request)
  end

  def sync_transactions(access_token, cursor: nil)
    request = Plaid::TransactionsSyncRequest.new(
      access_token: access_token,
      cursor: cursor
    )
    @client.transactions_sync(request)
  end

  private

  def plaid_env
    case ENV.fetch("PLAID_ENV", "sandbox")
    when "production" then "production"
    when "development" then "development"
    else "sandbox"
    end
  end
end
