require "nopassword"

module NoPassword
  class Engine < ::Rails::Engine
  end
end

require "extensions/action_dispatch/routing/mapper"
