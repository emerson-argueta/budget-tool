class RegistrationsController < Devise::RegistrationsController
  before_action :check_registration_allowed, only: [:new, :create]

  private

  def check_registration_allowed
    if User.exists?
      redirect_to root_path, alert: "Registration is closed."
    end
  end
end
