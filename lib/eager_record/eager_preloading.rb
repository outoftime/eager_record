module EagerRecord
  module EagerPreloading
    class <<self
      def install
        ActiveRecord::Base.module_eval do
          extend(EagerRecord::EagerPreloading::BaseExtensions)
        end
        ActiveRecord::Associations::AssociationProxy.module_eval { include(EagerRecord::EagerPreloading::AssociationProxyExtensions) }
        ActiveRecord::Associations::AssociationCollection.module_eval { include(EagerRecord::EagerPreloading::AssociationCollectionExtensions) }
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
        end
      end
  
      def load_target_with_eager_preloading
        if @reflection.options[:conditions].nil? && (!@owner.new_record? || foreign_key_present)
          if !loaded?
            if originating_collection = @owner.instance_variable_get(:@originating_collection)
              @owner.class.__send__(:preload_associations, originating_collection, @reflection.name)
              return target if loaded?
            end
          end
        end
        load_target_without_eager_preloading
      end
    end
  end
end
