class Codey::EmailAuthenticationsController < ApplicationController
  before_action :assign_verification, only: %i[edit update destroy]

  def new
    @email_authentication = Codey::EmailAuthentication.new
  end

  def create
    @email_authentication = Codey::EmailAuthentication.new(email_authentication_params)

    if @email_authentication.valid?
      deliver_email @email_authentication
      @verification = @email_authentication.verification
      # Next up we want to display the verify screen.
      render :edit
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    @verification.destroy!
  end

  def update
    if @verification.valid?
      valid_verification @verification.data
    else
      render :edit, status: :unprocessable_entity
    end
  end

  protected
    # Override this with your own logic to do something with the valid data. For
    # example, you might setup the current user session here via:
    #
    # ```
    # def valid(email)
    #   session[:user_id] = User.find_or_create_by(email: email)
    #   redirect_to dashboard_url
    # end
    # ```
    def valid_verification(email)
      redirect_to root_url
    end

    # Email the user the secret, or do something to it.
    def deliver_email(authentication)
      Codey::EmailAuthenticationMailer.with(authentication: authentication).notification_email.deliver
    end

  private
    def email_authentication_params
      params.require(:codey_email_authentication).permit(:email)
    end

    def secret_params
      params.require(:codey_secret).permit(:code, :salt)
    end

    def verification_params
      params.require(:codey_verification).permit(:code, :salt)
    end

    def assign_verification
      @verification = Codey::Verification.new(verification_params)
    end

    def find_secret
      Codey::Secret.find_by_salt! secret_params.fetch(:salt)
    end
end
