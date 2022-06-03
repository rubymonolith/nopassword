require "nopassword/version"
require "nopassword/encryptor"
require "nopassword/random_code_generator"
require "pathname"

module NoPassword
  def self.root
    Pathname.new(__dir__).join("..")
  end
end

require "nopassword/engine"

# Blurg, without this require, the inflector won't properly inflect the `nopassword_engine:install:migrations`
# task from the `rails g install nopassword:install` task.
require_relative "../config/initializers/inflections.rb"

