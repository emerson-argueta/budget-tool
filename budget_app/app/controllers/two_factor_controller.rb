class TwoFactorController < ApplicationController
  layout "devise"
  skip_before_action :authenticate_user!
  before_action :require_otp_session

  def setup
    @user = otp_user
    @qr_svg = RQRCode::QRCode.new(@user.otp_provisioning_uri)
      .as_svg(offset: 0, color: "000", shape_rendering: "crispEdges", module_size: 5, standalone: true)
  end

  def enable
    user = otp_user
    if user.verify_otp(params[:otp_attempt])
      user.update!(otp_required_for_login: true)
      complete_sign_in(user)
    else
      flash[:alert] = "Invalid code, please try again."
      redirect_to two_factor_setup_path
    end
  end

  def verify
  end

  def authenticate
    user = otp_user
    if user.verify_otp(params[:otp_attempt])
      complete_sign_in(user)
    else
      flash[:alert] = "Invalid code, please try again."
      redirect_to two_factor_verify_path
    end
  end

  private

  def require_otp_session
    redirect_to new_user_session_path unless session[:otp_user_id].present?
  end

  def otp_user
    User.find(session[:otp_user_id])
  end

  def complete_sign_in(user)
    session.delete(:otp_user_id)
    sign_in(user)
    redirect_to authenticated_root_path
  end
end
