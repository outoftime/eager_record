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
      base.has_many :_temporary_association_for_scoped_preloading, :class_name => 'Object', :readonly => true
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
      association_name = :"_temporary_association_for_scoped_preloading"
      reflection_name = @reflection.name
      current_scope = @reflection.options.merge(current_scoped_methods[:find])
      scope_key = current_scope.inspect
      if scoped_preloaded_associations = @owner.instance_variable_get(:@scoped_preloaded_associations)
        if preloaded_association = scoped_preloaded_associations[reflection_name][scope_key]
          return preloaded_association
        end
      end
      if originating_collection = @owner.instance_variable_get(:@originating_collection)
        reflection = @owner.class.__send__(
          :create_has_many_reflection,
          association_name,
          current_scope.merge(
            :class_name => @reflection.klass.name,
            :readonly => true
          )
        )
        originating_collection.each do |record|
          association = ActiveRecord::Associations::HasManyAssociation.new(record, reflection)
          record.__send__(:association_instance_set, association_name, association)
        end
        @owner.class.__send__(:preload_has_many_association, originating_collection, reflection)
        originating_collection.each do |record|
          record.instance_eval do
            @scoped_preloaded_associations ||= Hash.new { |h, k| h[k] = {} }
            @scoped_preloaded_associations[reflection_name][scope_key] =
              association_instance_get(association_name)
            association_instance_set(association_name, nil)
          end
        end
      end
      @owner.instance_variable_get(:@scoped_preloaded_associations)[reflection_name][scope_key]
    end
  end
end
