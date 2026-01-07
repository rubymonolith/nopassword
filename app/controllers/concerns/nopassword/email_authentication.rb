module NoPassword
  # Controller concern that provides the email authentication flow.
  # Include this in your controller to get the full authentication flow,
  # or override individual methods to customize behavior.
  #
  # Example:
  #   class SessionsController < ApplicationController
  #     include NoPassword::EmailAuthentication
  #
  #     def verification_succeeded(email)
  #       self.current_user = User.find_or_create_by(email: email)
  #       redirect_to dashboard_url
  #     end
  #   end
  module EmailAuthentication
    extend ActiveSupport::Concern

    included do
      include Routable

      routes.draw do |controller|
        resources :email_authentications, controller:, except: :destroy do
          collection do
            delete :destroy
          end
        end
      end

      before_action :set_authentication
      before_action :set_verification, only: [:show, :update]
      helper_method :create_url, :show_url
    end

    def new
    end

    def create
      @authentication.email = authentication_params[:email]
      @authentication.return_url ||= after_authentication_url

      if @authentication.valid? && @authentication.challenge.save
        @authentication.save
        deliver_challenge(@authentication.challenge)
        render :create, status: :accepted
      else
        render :new, status: :unprocessable_entity
      end
    end

    def show
      # Confirmation page - user clicks link in email and lands here
    end

    def update
      if @verification.verify
        email = @authentication.email
        @authentication.delete
        verification_succeeded(email)
      elsif @verification.different_browser?
        verification_different_browser(@verification)
      elsif @verification.expired?
        verification_expired(@verification)
      else
        verification_failed(@verification)
      end
    end

    def destroy
      @authentication.delete
      redirect_to root_url
    end

    protected

    # Override to handle successful verification.
    # This is where you'd set up the user session.
    def verification_succeeded(email)
      redirect_to @authentication.return_url || root_url
    end

    # Override to handle failed verification (wrong token).
    def verification_failed(verification)
      flash.now[:alert] = verification.errors.full_messages.to_sentence
      render :show, status: :unprocessable_entity
    end

    # Override to handle expired verification.
    def verification_expired(verification)
      flash[:alert] = "Link has expired. Please try again."
      redirect_to url_for(action: :new)
    end

    # Override to handle verification opened in a different browser.
    def verification_different_browser(verification)
      flash.now[:alert] = verification.errors.full_messages.to_sentence
      render :show, status: :unprocessable_entity
    end

    # Override to customize how the challenge is delivered.
    # Default uses ActionMailer.
    def deliver_challenge(challenge)
      EmailAuthenticationMailer
        .with(email: challenge.email, url: show_url(challenge.token))
        .authentication_email
        .deliver_later
    end

    # Override to set a default return URL after authentication.
    def after_authentication_url
      root_url
    end

    # URL helpers for forms
    def create_url
      url_for(action: :create)
    end

    def show_url(token = nil)
      if token
        url_for(action: :show, id: token)
      else
        url_for(action: :show, id: params[:id])
      end
    end

    private

    def set_authentication
      @authentication = Email::Authentication.new(session)
    end

    def set_verification
      @verification = @authentication.verification(token: params[:id])
    end

    def authentication_params
      params.require(:nopassword_email_authentication).permit(:email)
    end
  end
end
