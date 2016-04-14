# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'mondo_export/version'

Gem::Specification.new do |spec|
  spec.name          = "mondo_export"
  spec.version       = MondoExport::VERSION
  spec.authors       = ["Timothy Stott"]
  spec.email         = ["stott.timothy@gmail.com"]

  spec.summary       = %q{Export Mondo transactions}
  spec.description   = %q{Provides an executable to export Mondo transactions to file}
  spec.homepage      = ""
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
  # delete this section to allow pushing this gem to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.executables   = ["mondox"]
  spec.require_paths = ["lib"]

  spec.add_dependency "activesupport", "~> 4.0.0"
  spec.add_dependency "bundler", "~> 1.11"
  spec.add_dependency "mondo", "~> 0.5.0"

  spec.add_development_dependency "bundler", "~> 1.11"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
