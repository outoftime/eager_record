 'rubygems'
require 'active_record'
require 'digest'

module EagerRecord
  autoload :VERSION, File.join(File.dirname(__FILE__), 'eager_record', 'version')
  autoload :EagerPreloading, File.join(File.dirname(__FILE__), 'eager_record', 'eager_preloading')
  autoload :ScopedPreloading, File.join(File.dirname(__FILE__), 'eager_record', 'scoped_preloading')

  class <<self
    def install
      EagerPreloading.install
      ScopedPreloading.install
    end
  end
end
