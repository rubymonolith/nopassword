require_relative "lib/nopassword/version"

Gem::Specification.new do |spec|
  spec.name        = "nopassword"
  spec.version     = NoPassword::VERSION
  spec.authors     = ["Brad Gessler"]
  spec.email       = ["brad@rocketship.io"]
  spec.homepage    = "https://github.com/rocketshipio/nopassword"
  spec.summary     = "Passwordless login to Rails applications via email"
  spec.description = "NoPassword is a toolkit that makes it easy to implement temporary, secure login codes initiated from peoples' web browsers so they can login to Rails applications via email, SMS, CLI, QR Codes, or any other side-channel."
  spec.license     = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the "allowed_push_host"
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "https://github.com/rocketshipio/nopassword/releases"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.add_dependency "rails", ">= 7.0.1"
  spec.add_dependency "zeitwerk", "~> 2.0"
  spec.add_dependency "http", "~> 5.1"
  spec.add_dependency "jwt", "~> 2.8"
  spec.add_dependency "uri-builder", "~> 0.1.5"
  spec.add_development_dependency "rspec-rails"
end
