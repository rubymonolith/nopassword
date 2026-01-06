module NoPassword
  module Link
    # Validates a token provided via a link against the challenge stored in session.
    # Uses constant-time comparison to prevent timing attacks.
    class Verification
      include ActiveModel::Model
      include ActiveModel::Validations

      attr_reader :challenge, :provided_token

      validate :validate_token_present
      validate :validate_token_matches
      validate :validate_not_expired

      def initialize(challenge:, provided_token:)
        @challenge = challenge
        @provided_token = provided_token
      end

      def verify
        valid?
      end

      # For form routing - verification is always "persisted" (exists in session)
      def persisted?
        true
      end

      # For form routing - use the provided token as the ID
      def to_param
        provided_token
      end

      def expired?
        return true if challenge.created_at.nil?
        Time.current > challenge.expires_at
      end

      # Returns true if no challenge exists in session (e.g., different browser)
      def missing_challenge?
        challenge.token.blank?
      end

      # Alias for clarity - this is the most common reason for missing challenge
      def different_browser?
        missing_challenge?
      end

      private

      def validate_token_present
        if challenge.token.blank?
          errors.add(:base, "This link must be opened in the same browser where you requested it. Please go back to that browser, or request a new link here.")
        elsif provided_token.blank?
          errors.add(:base, "No token provided")
        end
      end

      def validate_token_matches
        return if errors.any?

        unless ActiveSupport::SecurityUtils.secure_compare(challenge.token.to_s, provided_token.to_s)
          errors.add(:token, "is invalid")
        end
      end

      def validate_not_expired
        return if errors.any?

        if expired?
          errors.add(:base, "Link has expired. Please request a new one.")
        end
      end
    end
  end
end
