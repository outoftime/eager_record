begin
  require 'spec'
  require 'active_record'
rescue LoadError => e
  if require 'rubygems' then retry
  else raise(e)
  end
end


ActiveRecord::Base.establish_connection(
  :adapter => 'sqlite3',
  :database => File.join(File.dirname(__FILE__), '..', 'test.db')
)


require File.join(File.dirname(__FILE__), '..', '..', 'lib', 'eager_record')
require File.join(File.dirname(__FILE__), '..', '..', 'rails', 'init.rb')

Spec::Runner.configure do |config|
  config.before :all do
    stdout, stderr = $stdout, $stderr
    $stdout = $stderr = StringIO.new
    require File.join(File.dirname(__FILE__), '..', 'schema.rb')
    $stdout, $stderr = stdout, stderr
    Dir.glob(File.join(File.dirname(__FILE__), '..', 'support', 'models', '*.rb')).each do |model|
      require(model)
    end
  end

  config.after :each do
    Dir.glob(File.join(File.dirname(__FILE__), '..', 'support', 'models', '*.rb')).each do |file|
      model = File.basename(file, File.extname(file)).classify.constantize
      ActiveRecord::Base.connection.execute("DELETE FROM #{model.table_name}")
    end
  end
end
