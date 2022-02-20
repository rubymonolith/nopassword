require "magiclink"

module Magiclink
  class Engine < ::Rails::Engine
    config.action_mailer.preview_path = Magiclink.root.join("spec/mailers/previews")
    # binding.pry
    # config.inflector.inflect.acronym "Magiclink"
  end
end
