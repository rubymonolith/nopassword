require "nopassword"

module NoPassword
  class Engine < ::Rails::Engine
  end
end

require_relative "../extensions/action_dispatch/routing/mapper"
