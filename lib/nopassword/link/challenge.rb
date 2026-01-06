module NoPassword
  module Link
    # Generates and stores a secure token for link-based authentication.
    # The token is stored in the session and sent via a side channel (email, SMS, etc).
    class Challenge < Base
      TOKEN_SIZE = 16 # 16 bytes = 128 bits of entropy
      DEFAULT_TTL = 10.minutes

      attribute :identifier, :string
      attribute :token, :string
      attribute :created_at, :datetime
      attribute :ttl, :integer, default: -> { DEFAULT_TTL.to_i }

      validates :identifier, presence: true

      def save
        return false unless valid?
        generate_token!
        super
      end

      def expires_at
        created_at + ttl.seconds if created_at
      end

      private

      def generate_token!
        self.token = SecureRandom.hex(TOKEN_SIZE)
        self.created_at = Time.current
      end
    end
  end
end
