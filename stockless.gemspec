# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'stockless/version'

Gem::Specification.new do |spec|
  spec.name          = "stockless"
  spec.version       = Stockless::VERSION
  spec.authors       = ["David La Chasse"]
  spec.email         = ["david.lachasse@gmail.com"]
  spec.description   = %q{Pulls in Visr.net inventory in set increments of time}
  spec.summary       = %q{Pulls in Visr.net inventory in set increments of time}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
end
