require 'bundler/gem_tasks'

task :release => :test

desc 'run tests'
task :test do
  system('rspec', 'spec/examples')
end
