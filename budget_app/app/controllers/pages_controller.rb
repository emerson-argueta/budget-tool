class PagesController < ApplicationController
  layout "devise"
  skip_before_action :authenticate_user!

  def privacy_policy
  end
end
