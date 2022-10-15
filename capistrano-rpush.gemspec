# frozen_string_literal: true

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'capistrano/rpush/version'

Gem::Specification.new do |spec|
  spec.name          = 'capistrano-rpush'
  spec.version       = Capistrano::RpushPlugin::VERSION
  spec.authors       = ['Mel Riffe', 'Cliff Braton']
  spec.email         = ['mel@juicyparts.com', 'cliff.braton@gmail.com']
  spec.summary       = "Capistrano3 plugin with basic 'start', 'stop' commands for rpush."
  spec.description   = 'A set of Capistrano3 tasks to controll a deployed Rpush installation. The tasks include: restart, start, status, and stop.'
  spec.homepage      = 'http://juicyparts.com/capistrano-rpush'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.post_install_message = 'Thanks for installing the Capistrano::Rpush plugin!'
  spec.metadata = {
    'source_code' => 'https://github.com/juicyparts/capistrano-rpush',
    'issue_tracker' => 'https://github.com/juicyparts/capistrano-rpush/issues'
  }

  spec.add_dependency 'capistrano', '>= 3.9.0'
  spec.add_dependency 'capistrano-bundler'
  spec.add_dependency 'rpush', '>= 2.7'

  spec.add_development_dependency 'bundler', '~> 2.2'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.6'
end
