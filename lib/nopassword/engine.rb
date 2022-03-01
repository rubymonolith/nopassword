require "nopassword"

module NoPassword
  class Engine < ::Rails::Engine
    config.action_mailer.preview_path = NoPassword.root.join("spec/mailers/previews")
  end
end
