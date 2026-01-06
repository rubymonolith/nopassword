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

      def expired?
        return true if challenge.created_at.nil?
        Time.current > challenge.expires_at
      end

      private

      def validate_token_present
        if challenge.token.blank?
          errors.add(:base, "No authentication challenge found")
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
