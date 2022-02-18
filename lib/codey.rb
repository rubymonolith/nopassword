require "codey/version"
require "codey/encryptor"
require "codey/random_code_generator"
require "pathname"

module Codey
  def self.root
    Pathname.new(__dir__).join("..")
  end
end

require "codey/engine"
