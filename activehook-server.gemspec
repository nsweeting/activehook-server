# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'activehook/server/version'

Gem::Specification.new do |spec|
  spec.name          = "activehook-server"
  spec.version       = Activehook::Server::VERSION
  spec.authors       = ["Nicholas Sweeting"]
  spec.email         = ["nsweeting@gmail.com"]

  spec.summary       = "Fast and simple webhook delivery microservice for Ruby."
  spec.description   = "Fast and simple webhook delivery microservice for Ruby."
  spec.homepage      = "TODO: Put your gem's website or public repo URL here."
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.executables   = %w( activehook-server )
  spec.require_paths = %w( lib/activehook )

  spec.add_runtime_dependency     "redis", "~> 3.3"
  spec.add_runtime_dependency     "connection_pool", "~> 2.2"
  spec.add_runtime_dependency     "puma", "~> 3.4"
  spec.add_runtime_dependency     "rack"
  spec.add_development_dependency "bundler", "~> 1.12"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "byebug", "~> 5.0"
  spec.add_development_dependency "fakeredis", "~> 0.5"
end
