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
      verification_succeeded @verification.data
    elsif @verification.has_expired?
      verification_expired @verification
    elsif @verification.has_exeeded_remaining_attempts?
      verification_exceeded_attempts @verification
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
    def verification_succeeded(email)
      redirect_to root_url
    end

    # Override with your own logic to deliver a code to the user.
    def deliver_authentication(authentication)
      Codey::EmailAuthenticationMailer.with(authentication: authentication).notification_email.deliver
    end

    # Override with logic for when verification attempts are exceeded. For
    # example, you might want to tweak the flash message that's displayed
    # or redirect them to a page other than the one where they'd re-verify.
    def verification_exceeded_attempts(verification)
      flash_error "The number of times the code can be tried has been exceeded."
      redirect_to url_for(action: :new)
    end

    # Override with logic for when verification has expired. For
    # example, you might want to tweak the flash message that's displayed
    # or redirect them to a page other than the one where they'd re-verify.
    def verification_expired(verification)
      flash_error "The code has expired."
      redirect_to url_for(action: :new)
    end

    def flash_error(message)
      flash[:codey_error] = message
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
