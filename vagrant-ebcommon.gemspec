# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'vagrant-ebcommon/version'

Gem::Specification.new do |spec|
  spec.name          = "vagrant-ebcommon"
  spec.version       = VagrantPlugins::Ebcommon::VERSION
  spec.authors       = ["Michael Hahn"]
  spec.email         = ["mhahn@eventbrite.com"]
  spec.description   = %q{Vagrant plugin to execute various Eventbrite workflows.}
  spec.summary       = spec.description
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
end
