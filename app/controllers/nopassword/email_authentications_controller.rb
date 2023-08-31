class NoPassword::EmailAuthenticationsController < ApplicationController
  before_action :assign_authentication

  # These are needed to make wiring up forms a little easier for the developer.
  helper_method :update_url, :create_url

  def new
  end

  def show
    fail "this should run through a model" if Rails.env.production?

    if @authentication.authentic_token? params[:token]
      authentication_succeeded @authentication.email
      @authentication.destroy
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def create
    @authentication.assign_attributes authentication_params
    if @authentication.valid?
      deliver_authentication @authentication.email, generate_email_verification_url
      render :create, status: :accepted
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    # We'll let users invalidate their verification link if they need to do so for
    # any reasons.
    @authentication.destroy
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
    def authentication_succeeded(email)
      redirect_to root_url
    end

    # Override with your own logic to deliver a code to the user.
    def deliver_authentication(email, link)
      NoPassword::EmailAuthenticationMailer.with(email: email, link: link).notification_email.deliver
    end

    # # Override with logic for when authentication attempts are exceeded. For
    # # example, you might want to tweak the flash message that's displayed
    # # or redirect them to a page other than the one where they'd re-verify.
    # def authentication_exceeded_attempts(authentication)
    #   flash[:nopassword_status] =  "The number of times the code can be tried has been exceeded."
    #   redirect_to url_for(action: :new)
    # end

    # # Override with logic for when authentication has expired. For
    # # example, you might want to tweak the flash message that's displayed
    # # or redirect them to a page other than the one where they'd re-verify.
    # def authentication_expired(authentication)
    #   flash[:nopassword_status] =  "The code has expired."
    #   redirect_to url_for(action: :new)
    # end

    def create_url
      url_for(action: :create)
    end

    def update_url
      url_for(action: :updatem, id: params.fetch(:id))
    end

  private
    def authentication_params
      params.require(:nopassword_email_authentication).permit(:email)
    end

    def authentication_token
      params.require(:id)
    end

    def assign_authentication
      @authentication = NoPassword::EmailAuthentication.new(session: session)
    end

    def generate_email_verification_url
      email_authentication_url(token: @authentication.generate_token)
    end
end
