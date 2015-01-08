# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "vagrant-scriptrock/version"

Gem::Specification.new do |spec|
  spec.name          = "vagrant-scriptrock"
  spec.version       = VagrantPlugins::ScriptRock::VERSION
  spec.authors       = ["Mark Sheahan"]
  spec.email         = ["mark.sheahan@scriptrock.com"]
  spec.homepage      = "https://github.com/ScriptRock/vagrant-scriptrock"
  spec.summary       = "Vagrant plugin for ScriptRock Guardrail node registry/deletion when Vagrant VMs are provisioned/destroyed"
  spec.description   = '''This plugin will install a Guardrail public key ~/.ssh/authorized_keys
on the instantiated vm, register the VM as a new node on the target Guardrail site,
and delete the Guardrail node when the VM is destroyed.'''
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "httparty"
  spec.add_runtime_dependency "httparty"
end

