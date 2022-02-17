class Codey::EmailAuthenticationsController < ApplicationController
  before_action :assign_verification, only: %i[edit update destroy]
  before_action :assign_email_authentication, only: :create
  before_action :initialize_and_assign_email_authentication, only: :new

  def new
  end

  def create
    if @email_authentication.valid?
      deliver_authentication @email_authentication
      @verification = @email_authentication.verification
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
    # Override with your own logic to do something with the valid data. For
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

    # Override with your own logic to deliver a code to the user.
    def deliver_authentication(authentication)
      Codey::EmailAuthenticationMailer.with(authentication: authentication).notification_email.deliver
    end

  private
    def email_authentication_params
      params.require(:codey_email_authentication).permit(:email)
    end

    def verification_params
      params.require(:codey_verification).permit(:code, :salt)
    end

    def assign_verification
      @verification = Codey::Verification.new(verification_params)
    end

    def assign_email_authentication
      @email_authentication = Codey::EmailAuthentication.new(email_authentication_params)
    end

    def initialize_and_assign_email_authentication
      @email_authentication = Codey::EmailAuthentication.new
    end
end
