module ActionDispatch
  module Routing
    class Mapper
      def nopassword(controller_class, *, **, &)
        if controller_class.respond_to?(:routes) and controller_class.routes.routable?
          instance_exec(controller_class.controller_path, *, **, &controller_class.routes)
        else
          raise ArgumentError, "controller_class must respond to :routes"
        end
      end
    end
  end
end
