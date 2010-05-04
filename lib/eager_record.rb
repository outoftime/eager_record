 'rubygems'
require 'active_record'
require 'digest'

module EagerRecord
  autoload :VERSION, File.join(File.dirname(__FILE__), 'eager_record', 'version')

  TEMPORARY_SCOPED_PRELOAD_ASSOCIATION = :"_temporary_association_for_scoped_preloading"

  class <<self
    def install
      ActiveRecord::Base.module_eval do
        extend(EagerRecord::BaseExtensions::ClassMethods)
        include(EagerRecord::BaseExtensions::InstanceMethods)
      end
      ActiveRecord::Associations::AssociationProxy.module_eval { include(EagerRecord::AssociationProxyExtensions) }
      ActiveRecord::Associations::AssociationCollection.module_eval { include(EagerRecord::AssociationCollectionExtensions) }
      ActiveRecord::Associations::HasManyAssociation.module_eval { include(EagerRecord::HasManyAssociationExtensions) }
    end

    def use_scoped_preload=(flag)
      @use_scoped_preload = flag
    end

    def use_scoped_preload?
      !!@use_scoped_preload
    end
  end

  module BaseExtensions
    module ClassMethods
      def self.extended(base)
        (class <<base; self; end).module_eval do
          alias_method_chain :find_by_sql, :eager_preloading
        end
      end

      def find_by_sql_with_eager_preloading(*args)
        collection = find_by_sql_without_eager_preloading(*args)
        grouped_collections = collection.group_by { |record| record.class }
        grouped_collections.values.each do |grouped_collection|
          if grouped_collection.length > 1
            grouped_collection.each do |record|
              record.instance_variable_set(:@originating_collection, grouped_collection)
            end
          end
        end
        collection
      end
    end

    module InstanceMethods
      def self.included(base)
        base.has_many TEMPORARY_SCOPED_PRELOAD_ASSOCIATION, :readonly => true
      end

      private

      def scoped_preloaded_associations
        @scoped_preloaded_associations ||= Hash.new { |h, k| h[k] = {}}
      end

      def scoped_preloaded_associations_for(association_name)
        scoped_preloaded_associations[association_name.to_sym]
      end
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
          association_name = @reflection.name
          @owner.class.__send__(:preload_associations, originating_collection, association_name)
          new_association = @owner.__send__(:association_instance_get, association_name)
          if new_association && __id__ != new_association.__id__ && new_association.loaded?
            @target = new_association.target
            @loaded = true
            return
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
      if EagerRecord.use_scoped_preload? && originating_collection = @owner.instance_variable_get(:@originating_collection)
        find_using_scoped_preload(originating_collection, *args)
      else
        find_without_eager_preloading(*args)
      end
    end

    private

    # 
    # Subclasses can override this
    #
    def find_using_scoped_preload(originating_collection, *args)
      find_without_eager_preloading(*args)
    end
  end

  module HasManyAssociationExtensions
    def find_using_scoped_preload(originating_collection, *args)
      options = args.extract_options!
      reflection_name = @reflection.name
      current_scope = 
        if current_scoped_methods && current_scoped_methods[:find] #XXX regression test
          @reflection.options.merge(current_scoped_methods[:find])
        else
          @reflection.options
        end
      owner_class = @owner.class
      reflection_class = @reflection.klass
      scope_key = current_scope.inspect
      if preloaded_association = @owner.__send__(:scoped_preloaded_associations_for, reflection_name)[scope_key]
        return preloaded_association
      end
      reflection = owner_class.__send__(
        :create_has_many_reflection,
        TEMPORARY_SCOPED_PRELOAD_ASSOCIATION,
        current_scope.merge(
          :class_name => reflection_class.name,
          :readonly => true
      )
      )
      originating_collection.each do |record|
        association = ActiveRecord::Associations::HasManyAssociation.new(record, reflection)
        record.__send__(:association_instance_set, TEMPORARY_SCOPED_PRELOAD_ASSOCIATION, association)
      end
      owner_class.__send__(:preload_has_many_association, originating_collection, reflection)
      originating_collection.each do |record|
        record.instance_eval do
          @scoped_preloaded_associations ||= Hash.new { |h, k| h[k] = {} }
          @scoped_preloaded_associations[reflection_name][scope_key] =
            association_instance_get(TEMPORARY_SCOPED_PRELOAD_ASSOCIATION)
          association_instance_set(TEMPORARY_SCOPED_PRELOAD_ASSOCIATION, nil)
        end
      end
      @owner.__send__(:scoped_preloaded_associations_for, reflection_name)[scope_key]
    end
  end
end
