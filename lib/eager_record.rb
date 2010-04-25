require 'rubygems'
require 'active_record'
require 'digest'

module EagerRecord
  class <<self
    def install
      ActiveRecord::Base.module_eval { extend(EagerRecord::BaseExtensions) }
      ActiveRecord::Associations::AssociationProxy.module_eval { include(EagerRecord::AssociationProxyExtensions) }
      ActiveRecord::Associations::AssociationCollection.module_eval { include(EagerRecord::AssociationCollectionExtensions) }
    end
  end

  module BaseExtensions
    def self.extended(base)
      (class <<base; self; end).module_eval do
        alias_method_chain :find_by_sql, :eager_preloading
      end
    end

    def find_by_sql_with_eager_preloading(*args)
      collection = find_by_sql_without_eager_preloading(*args)
      if collection.length > 1
        collection.each do |record|
          record.instance_variable_set(:@originating_collection, collection)
        end
      end
      collection
    end
  end

  module AssociationProxyExtensions
    def self.included(base)
      base.module_eval do
        alias_method_chain :load_target, :eager_preloading
      end
    end

    def load_target_with_eager_preloading
      return nil unless defined?(@loaded)

      if !loaded? and (!@owner.new_record? || foreign_key_present)
        if originating_collection = @owner.instance_variable_get(:@originating_collection)
          #XXX STI classes seem to have trouble preloading associations -- need to look into this more.
          association_name = @reflection.name
          if @owner.class.reflect_on_association(association_name)
            @owner.class.__send__(:preload_associations, originating_collection, association_name)
            return @target if loaded?
          end
        end
      end
      load_target_without_eager_preloading
    end
  end

  module AssociationCollectionExtensions
    def self.included(base)
      base.module_eval do
        alias_method_chain :load_target, :eager_preloading
        alias_method_chain :find, :eager_preloading
      end
    end

    def load_target_with_eager_preloading
      if !@owner.new_record? || foreign_key_present
        if !loaded?
          if originating_collection = @owner.instance_variable_get(:@originating_collection)
            @owner.class.__send__(:preload_associations, originating_collection, @reflection.name)
            return target if loaded?
          end
        end
      end
      load_target_without_eager_preloading
    end

    # 
    # Because of some likely unintentional plumbing in the scoping/association
    # delegation chain, current_scoped_methods returns an association proxy's
    # scope when called on the association collection. This means that, among
    # other things, a named scope called on an association collection will
    # duplicate the association collection's SQL restriction.
    #
    def current_scoped_methods
      @reflection.klass.__send__(:current_scoped_methods)
    end

    def find_with_eager_preloading(*args)
      options = args.extract_options!
      options_digest = Digest::SHA1.hexdigest(options.inspect)[0..7]
      association_name = :"_preloadable_association_collection_#{options_digest}s"
      if false #FIXME options already exist
      else
        @owner.class.has_many(
          association_name,
          @reflection.options.merge(current_scoped_methods[:find]).merge(
            :class_name => @reflection.klass.name,
            :readonly => true
          )
        )
      end
      if originating_collection = @owner.instance_variable_get(:@originating_collection)
        @owner.class.__send__(:preload_associations, originating_collection, association_name)
      end
      @owner.__send__(association_name)
    end
  end
end
