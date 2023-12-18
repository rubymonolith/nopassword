require "nopassword"

module NoPassword
  class Engine < ::Rails::Engine
  end
end

require "nopassword/action_dispatch/routing/mapper"
