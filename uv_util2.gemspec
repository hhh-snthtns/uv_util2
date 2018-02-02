# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'uv_util2/version'

Gem::Specification.new do |spec|
  spec.name          = "uv_util2"
  spec.version       = UvUtil2::VERSION
  spec.authors       = ["aoyagikouhei"]
  spec.email         = ["aoyagi.kouhei@gmail.com"]
  spec.summary       = %q{uv_util2}
  spec.description   = %q{uv_util2}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3"
  spec.add_development_dependency "activesupport", "~> 4"
  spec.add_development_dependency "sequel", "~> 4"
  spec.add_development_dependency "pg", "~> 0"
  spec.add_development_dependency "moped", "~> 0"
  spec.add_development_dependency "fluent-logger"
  spec.add_development_dependency "google-cloud-bigquery", "~> 1.0.0"
end
