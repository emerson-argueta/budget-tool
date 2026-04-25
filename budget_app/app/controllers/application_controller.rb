class ApplicationController < ActionController::Base
  include Pagy::Method

  allow_browser versions: :modern
  stale_when_importmap_changes

  before_action :authenticate_user!

  helper_method :unassigned_transaction_count

  private

  def unassigned_transaction_count
    @unassigned_transaction_count ||= current_user.transactions.unassigned.count
  end
end
