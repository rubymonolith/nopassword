require "codey/version"
require "codey/encryptor"
require "codey/random_code_generator"
require "pathname"

module Codey
  def self.root
    Pathname.new(__dir__).join("..")
  end
end

# The engine needs Codey.root to load first so it can configure paths
# into the Codey gem properly.
require "codey/engine"
