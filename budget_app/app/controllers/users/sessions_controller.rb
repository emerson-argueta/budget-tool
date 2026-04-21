class Users::SessionsController < Devise::SessionsController
  def create
    user = User.find_by(email: params[:user][:email]&.downcase&.strip)

    unless user&.valid_password?(params[:user][:password])
      flash[:alert] = "Invalid email or password."
      return redirect_to new_user_session_path
    end

    session[:otp_user_id] = user.id

    if user.otp_required_for_login
      redirect_to two_factor_verify_path
    else
      user.generate_otp_secret! unless user.otp_secret.present?
      redirect_to two_factor_setup_path
    end
  end
end
