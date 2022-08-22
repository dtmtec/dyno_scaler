# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'dyno_scaler/version'

Gem::Specification.new do |gem|
  gem.name          = "dyno_scaler"
  gem.version       = DynoScaler::VERSION
  gem.authors       = ["Vicente Mundim"]
  gem.email         = ["vicente.mundim@gmail.com"]
  gem.description   = %q{Scale your dyno workers on Heroku as needed}
  gem.summary       = %q{Scale your dyno workers on Heroku as needed}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_dependency "platform-api"
  gem.add_dependency "activesupport"
  gem.add_dependency "redis", ">= 4.5.1"
  gem.add_dependency "redis-namespace"
end
