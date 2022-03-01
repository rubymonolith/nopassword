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
