lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "event_sourceable/version"

Gem::Specification.new do |spec|
  spec.name          = "event-sourceable"
  spec.version       = EventSourceable::VERSION
  spec.authors       = ["Robert Graff"]
  spec.email         = ["robert_graff@yahoo.com"]

  spec.summary       = "EventSourceable is a minimal way of adding event sourcing to ActiveRecord models."
  spec.homepage      = "https://github.com/goldstar/event-sourceable"
  spec.license       = "MIT"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  
  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end

  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rspec-rails"
  spec.add_development_dependency "sqlite3", "~> 1.4"
  spec.add_development_dependency "byebug"

  spec.add_runtime_dependency "activerecord", "~> 6.0"
end
