module NoPassword
  module Email
    # Email-specific challenge that aliases identifier as email for convenience.
    class Challenge < Link::Challenge
      attr_reader :authentication

      # Validate email format (identifier is the email)
      validates :identifier, format: { with: URI::MailTo::EMAIL_REGEXP, message: "is invalid" }

      def initialize(session, authentication: nil, **)
        @authentication = authentication
        super(session, **)
      end

      # Convenience accessor - email is stored as identifier
      def email
        identifier
      end

      def email=(value)
        self.identifier = value
      end

      def save
        return false unless valid?
        # Sync email back to authentication before saving
        if authentication
          authentication.email = email
          authentication.save_without_validation
        end
        super
      end
    end
  end
end
