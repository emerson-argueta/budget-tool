class TransactionCategorizer
  def initialize(user)
    @user = user
    @rules = user.merchant_rules.includes(:budget_category)
  end

  def categorize(transaction)
    return if transaction.budget_category_id?

    rule = @rules.find { |r| r.matches?(transaction.display_name) }
    transaction.update!(budget_category: rule.budget_category) if rule
  end

  def categorize_all(transactions)
    transactions.each { |t| categorize(t) }
  end
end
