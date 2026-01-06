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
