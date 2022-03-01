class EmailAuthenticationsController < NoPassword::EmailAuthenticationsController
    # Override with your own logic to do something with the valid data. For
    # example, you might setup the current user session here via:
    #
    # ```
    # def verification_succeeded(email)
    #   self.current_user = User.find_or_create_by(email: email)
    #   redirect_to dashboard_url
    # end
    # ```
    def verification_succeeded(email)
      redirect_to root_url
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

    # Override with your own logic to deliver a code to the user.
    def deliver_authentication(authentication)
      NoPassword::EmailAuthenticationMailer.with(authentication: authentication).notification_email.deliver
    end
end
