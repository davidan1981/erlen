$:.push File.expand_path("../lib", __FILE__)

require 'erlen/version'

Gem::Specification.new do |s|
  s.name        = 'erlen'
  s.version     = Erlen::VERSION
  s.summary     = 'Ruby library for JSON schema creation, validation, and serialization'
  s.description = 'Erlen is a Ruby library for JSON schema creation, validation, and serialization.'
  s.authors     = ['Tim Brenner', 'David An']
  s.email       = [
    'engineering@hireology.com',
    'timpbrenner@gmail.com',
    'davidan1981@gmail.com'
  ]
  s.platform    = Gem::Platform::RUBY
  s.files       = Dir['lib/**/*', 'MIT-LICENSE', 'README.md']
  s.license     = 'MIT'
  s.homepage    = 'https://github.com/Hireology/erlen'

  s.add_development_dependency 'rspec', '~> 3.1'
end
