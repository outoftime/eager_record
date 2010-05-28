require File.join(File.dirname(__FILE__), '..', 'environment')

begin
  require 'spec'
rescue LoadError => e
  if require 'rubygems' then retry
  else raise(e)
  end
end

require File.join(File.dirname(__FILE__), '..', 'support', 'helpers')

Spec::Runner.configure do |config|
  config.include(EagerRecord::SpecHelpers)

  config.before :all do
    stdout, stderr = $stdout, $stderr
    $stdout = $stderr = StringIO.new
    require File.join(File.dirname(__FILE__), '..', 'schema.rb')
    $stdout, $stderr = stdout, stderr
  end

  config.after :each do
    Dir.glob(File.join(File.dirname(__FILE__), '..', 'support', 'models', '*.rb')).each do |file|
      model = File.basename(file, File.extname(file)).classify.constantize
      ActiveRecord::Base.connection.execute("DELETE FROM #{model.table_name}")
    end
  end
end
