class RegistrationsController < Devise::RegistrationsController
  before_action :configure_permitted_parameters
  prepend_before_action :check_bitcoin, only: [:create]
  prepend_before_action :check_captcha, only: [:create]

  private

  def check_captcha
    return if verify_recaptcha

    self.resource = resource_class.new sign_up_params
    resource.validate
    set_minimum_password_length

    respond_with_navigational(resource) do
      flash.discard(:recaptcha_error)
      render :new
    end
  end

  def check_bitcoin
    if params[:user][:first_name].match(/bitcoin/i) || params[:user][:last_name].match(/bitcoin/i)
      flash[:error] = "You have used a banned first name, contact support if you think this is an error"
      redirect_to root_path
      return
    end
  end

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:first_name, :last_name])
    devise_parameter_sanitizer.permit(:account_update,
keys: [:password, :password_confirmation, :current_password, :first_name, :last_name, :address, :address2, :country, :phone])
  end
end
