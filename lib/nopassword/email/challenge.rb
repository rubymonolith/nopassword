module NoPassword
  module Email
    # Email-specific challenge that aliases identifier as email for convenience.
    class Challenge < Link::Challenge
      # Convenience accessor - email is stored as identifier
      def email
        identifier
      end

      def email=(value)
        self.identifier = value
      end
    end
  end
end
