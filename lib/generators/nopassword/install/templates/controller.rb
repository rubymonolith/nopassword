class EmailAuthenticationsController < NoPassword::EmailAuthenticationsController
  # Override to handle successful verification.
  # This is where you set up the user session.
  #
  # Example:
  #   def verification_succeeded(email)
  #     self.current_user = User.find_or_create_by(email: email)
  #     redirect_to dashboard_url
  #   end
  #
  def verification_succeeded(email)
    redirect_to root_url
  end

  # Override to handle expired links.
  # def verification_expired(verification)
  #   flash[:alert] = "Link has expired. Please try again."
  #   redirect_to url_for(action: :new)
  # end

  # Override to handle invalid tokens.
  # def verification_failed(verification)
  #   flash.now[:alert] = verification.errors.full_messages.to_sentence
  #   render :show, status: :unprocessable_entity
  # end

  # Override to customize how the link is delivered.
  # def deliver_challenge(challenge)
  #   NoPassword::EmailAuthenticationMailer
  #     .with(challenge: challenge, url: show_url(challenge.token))
  #     .authentication_email
  #     .deliver_later
  # end
end
