require "codey/version"
require "codey/encryptor"
require "pathname"

module Codey
  def self.root
    Pathname.new(__dir__).join("..")
  end
end

# The engine needs the root path to load first.
require "codey/engine"
