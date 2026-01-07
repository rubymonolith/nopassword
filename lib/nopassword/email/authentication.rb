module NoPassword
  module Email
    # Email-specific authentication that adds email validation and normalization.
    class Authentication < Session::Authentication
      attribute :email, :string

      validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }

      # Normalize email on assignment
      def email=(value)
        super(value&.strip&.downcase)
      end

      # Email is the identifier for this authentication type
      def identifier
        email
      end

      protected

      def build_challenge(**)
        Challenge.new(@session, authentication: self, identifier:, **)
      end
    end
  end
end
