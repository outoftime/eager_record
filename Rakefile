require File.expand_path('../lib/eager_record/version', __FILE__)
require 'fileutils'
require 'bundler/gem_tasks'

gem_path = File.expand_path("../eager_record-#{EagerRecord::VERSION}.gem", __FILE__)

task :release => :test

#desc 'package and release gem'
#task :release => [:test, :build, :push, :cleanup]
#
desc 'run tests'
task :test do
  system('rspec', 'spec/examples')
end
#
#desc 'build gem'
#task :build do
#  system('gem', 'build', 'eager_record.gemspec')
#end
#
#desc 'push gem to rubygems'
#task :push do
#  system('gem', 'push', gem_path)
#end
#
#desc 'remove packaged gem file'
#task :cleanup  do
#  FileUtils.rm(gem_path, :verbose => true)
#end
