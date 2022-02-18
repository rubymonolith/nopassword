require "codey"

module Codey
  class Engine < ::Rails::Engine
    config.action_mailer.preview_path = Codey.root.join("spec/mailers/previews")
  end
end
