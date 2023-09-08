require "pathname"
require "zeitwerk"

module NoPassword
  Loader = Zeitwerk::Loader.for_gem.tap do |loader|
    loader.inflector.inflect "nopassword" => "NoPassword"
    loader.inflector.inflect "oauth" => "OAuth"
    loader.setup
  end

  def self.root
    Pathname.new(__dir__).join("..")
  end
end

require "nopassword/engine" if defined? Rails

# Blurg, without this require, the inflector won't properly inflect the `nopassword_engine:install:migrations`
# task from the `rails g install nopassword:install` task.
require_relative "../config/initializers/inflections.rb"
