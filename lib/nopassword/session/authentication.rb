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
        @challenge ||= challenge_class.new(@session, identifier: identifier)
      end

      def verification(token:)
        verification_class.new(
          challenge: challenge_class.new(@session),
          provided_token: token
        )
      end

      def save
        return false unless valid?
        @session[session_key] = attributes.compact
        true
      end

      def save!
        save || raise(ActiveModel::ValidationError.new(self))
      end

      def delete
        @session.delete(session_key)
        challenge_class.delete(@session)
      end

      def persisted?
        false
      end

      protected

      # Override in subclass to use a different challenge class
      def challenge_class
        Link::Challenge
      end

      # Override in subclass to use a different verification class
      def verification_class
        Link::Verification
      end

      private

      def session_key
        @session_key ||= "nopassword_#{self.class.name.demodulize.underscore}".to_sym
      end
    end
  end
end
