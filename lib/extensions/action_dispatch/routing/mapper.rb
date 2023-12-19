module ActionDispatch
  module Routing
    class Mapper
      def nopassword(controller_class, *, **, &)
        if controller_class.respond_to? :routes
          instance_exec(*, **, &controller_class.routes) if controller_class.routes.routable?
        else
          raise ArgumentError, "controller_class must respond to :routes"
        end
      end
    end
  end
end
