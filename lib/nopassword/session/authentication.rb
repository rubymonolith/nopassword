module NoPassword
  module Session
    # Base authentication class that manages return_url and wraps Link challenge/verification.
    # Subclass this to add identifier validation (e.g., Email::Authentication adds email validation).
    class Authentication
      include ActiveModel::Model
      include ActiveModel::Attributes

      attribute :return_url, :string

      def initialize(session, **attributes)
        @session = session
        data = @session[session_key] || {}
        super(**data.symbolize_keys.merge(attributes))
      end

      # Override in subclass to return the identifier (email, phone, etc.)
      def identifier
        raise NotImplementedError, "Subclasses must implement #identifier"
      end

      def challenge
        @challenge ||= build_challenge(identifier:)
      end

      def verification(token:)
        build_verification(token:)
      end

      def save
        return false unless valid?
        @session[session_key] = attributes.compact
        true
      end

      def save!
        save || raise(ActiveModel::ValidationError.new(self))
      end

      # Save without running validations - useful for syncing from challenge
      def save_without_validation
        @session[session_key] = attributes.compact
        true
      end

      # Update session data, optionally yielding for modifications
      def self.update(session, **)
        new(session, **).tap do |instance|
          yield instance if block_given?
          instance.save_without_validation
        end
      end

      def delete
        @session.delete(session_key)
        Link::Challenge.delete(@session)
      end

      def persisted?
        false
      end

      protected

      # Override to customize how challenges are built
      def build_challenge(**)
        Link::Challenge.new(@session, **)
      end

      # Override to customize how verifications are built
      def build_verification(token:)
        Link::Verification.new(
          challenge: build_challenge,
          provided_token: token
        )
      end

      private

      def session_key
        @session_key ||= "nopassword_#{self.class.name.demodulize.underscore}".to_sym
      end
    end
  end
end
