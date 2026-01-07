require "pathname"
require "zeitwerk"

module NoPassword
  Loader = Zeitwerk::Loader.for_gem.tap do |loader|
    loader.ignore "#{__dir__}/generators"
    loader.ignore("#{__dir__}/extensions")
    loader.inflector.inflect "nopassword" => "NoPassword"
    loader.inflector.inflect "oauth" => "OAuth"
    loader.setup
  end

  def self.root
    Pathname.new(__dir__).join("..")
  end

  # Base error class for NoPassword exceptions
  class Error < StandardError; end

  # Raised when authentication is required but the user is not authenticated.
  # Carries context (email, return_url) that can be used to redirect to auth.
  class UnauthenticatedError < Error
    attr_reader :email, :return_url

    def initialize(email: nil, return_url: nil, message: "Authentication required")
      @email = email
      @return_url = return_url
      super(message)
    end
  end
end

require "nopassword/engine" if defined? Rails
