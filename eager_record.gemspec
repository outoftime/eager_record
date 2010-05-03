# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib/', __FILE__)

$:.unshift(lib) unless $:.include?(lib)

require 'eager_record/version'

Gem::Specification.new do |s|
  s.name = 'eager_record'
  s.version = EagerRecord::VERSION
  s.platform = Gem::Platform::RUBY
  s.authors = ['Mat Brown']
  s.email = 'mat@patch.com'
  s.homepage = 'http://github.com/outoftime/eager_record'
  s.summary = 'Automatic association preloading for ActiveRecord collections.'
  s.description = %q(EagerRecord extends ActiveRecord to automate association preloading. Each time a collection of more than one record is loaded from the database, each record remembers the collection that it is part of; then when one of those records has an association accessed, EagerRecord triggers a preload_associations for all the records in the originating collection. Never worry about that :include option again!)
  s.rubyforge_project = 'eager_record'

  s.add_development_dependency 'rspec'
  
  s.files = Dir.glob('lib/**/*') + %w(README.rdoc History.txt)
  s.require_path = 'lib'
end
