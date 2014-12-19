# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'norikra/version'

Gem::Specification.new do |spec|
  spec.name          = "norikra"
  spec.version       = Norikra::VERSION
  spec.authors       = ["TAGOMORI Satoshi"]
  spec.email         = ["tagomoris@gmail.com"]
  spec.summary       = %q{Schema-less stream processing server with SQL}
  spec.description   = %q{Norikra is a open source server software provides "Schema-les Stream Processing" with SQL, written in JRuby, runs on JVM, licensed under GPLv2.}
  spec.homepage      = "http://norikra.github.io/"
  spec.license       = "GPLv2"
  spec.platform      = "java"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib", "esper"]

  spec.add_runtime_dependency "mizuno", "~> 0.6"
  spec.add_runtime_dependency "rack"
  spec.add_runtime_dependency "thor"
  spec.add_runtime_dependency "msgpack-rpc-over-http-jruby", ">= 0.0.6"
  spec.add_runtime_dependency "norikra-client-jruby", ">= 1.1.0"
  spec.add_runtime_dependency "sinatra"
  spec.add_runtime_dependency "sinatra-contrib"
  spec.add_runtime_dependency "erubis"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "spork"
  spec.add_development_dependency "pry"
end
