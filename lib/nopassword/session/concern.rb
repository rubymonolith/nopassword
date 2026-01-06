module NoPassword
  module Session
    # Controller concern for managing authenticated sessions.
    # Include this in your ApplicationController to get session helpers.
    #
    # Example:
    #   class ApplicationController < ActionController::Base
    #     include NoPassword::Session::Concern
    #   end
    #
    #   class DashboardController < ApplicationController
    #     def show
    #       @user = authenticated  # Raises UnauthenticatedError if not authenticated
    #     end
    #   end
    module Concern
      extend ActiveSupport::Concern

      included do
        rescue_from NoPassword::UnauthenticatedError do |error|
          handle_unauthenticated(error)
        end

        helper_method :current_session, :authenticated?, :authenticated
      end

      protected

      # Returns the current authenticated session, or nil if not authenticated.
      # Override this to return your own session/user object.
      def current_session
        @current_session
      end

      # Sets the current session. Override to store in encrypted cookie.
      def current_session=(value)
        @current_session = value
      end

      # Returns the current session or raises UnauthenticatedError.
      # Use this in controllers that require authentication.
      def authenticated
        current_session || raise(UnauthenticatedError.new(return_url: request.url))
      end

      # Returns true if there is a current session.
      def authenticated?
        current_session.present?
      end

      # Pre-populate authentication data before starting the auth flow.
      # Useful when you know the user's email from another source (e.g., checkout).
      def preauth(**)
        authentication_class.new(session, **).tap(&:save)
      end

      # Override to specify which authentication class to use
      def authentication_class
        Email::Authentication
      end

      # Override to specify where to redirect for authentication
      def authentication_url
        raise NotImplementedError, "Override #authentication_url in your controller"
      end

      # Called when UnauthenticatedError is raised. Override to customize behavior.
      def handle_unauthenticated(error)
        authentication_class.new(session).tap do |auth|
          auth.email = error.email if error.email && auth.respond_to?(:email=)
          auth.return_url = error.return_url if error.return_url
          auth.save
        end
        redirect_to authentication_url
      end
    end
  end
end
