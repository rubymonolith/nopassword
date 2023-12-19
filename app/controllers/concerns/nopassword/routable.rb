module NoPassword
  # A tiny DSL that lets one describe the routes for the actions on a
  # controller class. This is meant to make the controller more "self-contained"
  # so that it can be mounted by the developer in the apporpriate spot, while
  # maintaining the structure intended by the developer.
  #
  # If the developer seeks full control over the routes, that's totally fine!
  # Just look at the source of the controller and map the actions to whatever
  # your preferences in your route file.
  module Routable
    class Routes
      def initialize
        @routes = nil
      end

      def draw(&routes)
        @routes = routes
      end

      def routable?
        @routes.present?
      end

      def to_proc
        @routes
      end
    end

    extend ActiveSupport::Concern

    included do
      cattr_accessor :routes, default: Routes.new
    end
  end
end
