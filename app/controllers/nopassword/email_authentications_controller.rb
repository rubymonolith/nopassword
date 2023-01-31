class NoPassword::EmailAuthenticationsController < ApplicationController
  before_action :assign_verification, only: %i[edit update destroy]
  before_action :assign_email_authentication, only: :create
  before_action :initialize_and_assign_email_authentication, only: :new

  # These are needed to make wiring up forms a little easier for the developer.
  helper_method :update_url, :create_url

  def new
  end

  def show
    redirect_to url_for(action: :new)
  end

  def create
    if @email_authentication.valid?
      deliver_authentication @email_authentication
      @verification = @email_authentication.verification
      render :edit, status: :accepted
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
    elsif @verification.has_exceeded_attempts?
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
      NoPassword::EmailAuthenticationMailer.with(authentication: authentication).notification_email.deliver
    end

    # Override with logic for when verification attempts are exceeded. For
    # example, you might want to tweak the flash message that's displayed
    # or redirect them to a page other than the one where they'd re-verify.
    def verification_exceeded_attempts(verification)
      flash[:nopassword_status] =  "The number of times the code can be tried has been exceeded."
      redirect_to url_for(action: :new)
    end

    # Override with logic for when verification has expired. For
    # example, you might want to tweak the flash message that's displayed
    # or redirect them to a page other than the one where they'd re-verify.
    def verification_expired(verification)
      flash[:nopassword_status] =  "The code has expired."
      redirect_to url_for(action: :new)
    end

    def create_url
      url_for(action: :create)
    end

    def update_url
      url_for(action: :update)
    end

  private
    def email_authentication_params
      params.require(:nopassword_email_authentication).permit(:email)
    end

    def verification_params
      params.require(:nopassword_verification).permit(:code, :salt, :data)
    end

    def assign_verification
      @verification = NoPassword::Verification.new(verification_params)
    end

    def assign_email_authentication
      @email_authentication = NoPassword::EmailAuthentication.new(email_authentication_params)
    end

    def initialize_and_assign_email_authentication
      @email_authentication = NoPassword::EmailAuthentication.new
    end
end
