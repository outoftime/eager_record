begin
  require 'bundler'
rescue LoadError => e
  if require 'rubygems' then retry
  else raise(e)
  end
end

Bundler.require(:default, :development)

ActiveRecord::Base.establish_connection(
  :adapter => 'sqlite3',
  :database => File.join(File.dirname(__FILE__), 'test.db')
)

require 'logger'
ActiveRecord::Base.logger = Logger.new(File.join(File.dirname(__FILE__), 'test.log'))

require File.join(File.dirname(__FILE__), '..', 'lib', 'eager_record')
require File.join(File.dirname(__FILE__), '..', 'rails', 'init.rb')
Dir.glob(File.join(File.dirname(__FILE__), 'support', 'models', '*.rb')).each do |model|
  require(model)
end
