require_relative "lib/codey/version"

Gem::Specification.new do |spec|
  spec.name        = "codey"
  spec.version     = Codey::VERSION
  spec.authors     = ["Brad Gessler"]
  spec.email       = ["bradgessler@gmail.com"]
  spec.homepage    = "https://github.com/rocketshipio/codey"
  spec.summary     = "Send codes with an assertion and make the person validate"
  spec.license     = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the "allowed_push_host"
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = spec.homepage

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.add_dependency "rails", ">= 7.0.1"
  spec.add_development_dependency "rspec-rails"
end
