require "pathname"
require "zeitwerk"

module NoPassword
  Loader = Zeitwerk::Loader.for_gem.tap do |loader|
    loader.ignore "#{__dir__}/generators"
    loader.inflector.inflect "nopassword" => "NoPassword"
    loader.inflector.inflect "oauth" => "OAuth"
    loader.setup
  end

  def self.root
    Pathname.new(__dir__).join("..")
  end
end

require "nopassword/engine" if defined? Rails
