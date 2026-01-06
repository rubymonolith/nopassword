module NoPassword
  module Link
    # Base class for session-stored objects in the Link authentication flow.
    # Provides ActiveModel compatibility and session persistence.
    class Base
      include ActiveModel::Model
      include ActiveModel::Attributes

      def initialize(session, **attributes)
        @session = session
        data = @session[session_key] || {}
        super(**data.symbolize_keys.merge(attributes))
      end

      def save
        return false unless valid?
        @session[session_key] = attributes.compact
        true
      end

      def save!
        save || raise(ActiveModel::ValidationError.new(self))
      end

      # Save without running validations - useful for partial updates
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
      end

      def self.delete(session)
        key = "nopassword_#{name.demodulize.underscore}".to_sym
        session.delete(key)
      end

      def persisted?
        false
      end

      private

      def session_key
        @session_key ||= "nopassword_#{self.class.name.demodulize.underscore}".to_sym
      end
    end
  end
end
