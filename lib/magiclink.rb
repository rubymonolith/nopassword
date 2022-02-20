require "magiclink/version"
require "magiclink/encryptor"
require "magiclink/random_code_generator"
require "pathname"

module Magiclink
  def self.root
    Pathname.new(__dir__).join("..")
  end
end

require "magiclink/engine"
