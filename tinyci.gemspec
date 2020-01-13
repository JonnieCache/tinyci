# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'tinyci/version'

Gem::Specification.new do |spec|
  spec.name          = 'tinyci'
  spec.version       = TinyCI::VERSION
  spec.authors       = ['Jonathan Davies']
  spec.email         = ['jonnie@cleverna.me']

  desc = 'A minimal Continuous Integration system, written in ruby, powered by git'
  spec.summary       = desc
  spec.description   = desc
  spec.homepage      = 'https://github.com/JonnieCache/tinyci'
  spec.license       = 'MIT'

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = 'https://rubygems.org'
  else
    raise 'RubyGems 2.0 or newer is required to protect against ' \
      'public gem pushes.'
  end

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.executables   = ['tinyci']
  spec.require_paths = ['lib']

  LOGO = File.read(File.expand_path('lib/tinyci/logo.txt', __dir__))

  spec.post_install_message = (LOGO % TinyCI::VERSION) + "\n"

  spec.add_development_dependency 'barrier'
  spec.add_development_dependency 'fuubar'
  spec.add_development_dependency 'guard-rspec'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'pry-byebug'
  spec.add_development_dependency 'pry-doc'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'redcarpet'
  spec.add_development_dependency 'rspec', '>= 3.8.0'
  spec.add_development_dependency 'rspec-nc'
  spec.add_development_dependency 'simplecov'
  spec.add_development_dependency 'terminal-notifier', '1.7.2'
  spec.add_development_dependency 'yard'
end
