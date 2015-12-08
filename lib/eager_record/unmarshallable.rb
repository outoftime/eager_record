module EagerRecord
  #
  # A wrapper for objects that we don't want to marshal. In particular, used
  # to wrap the @originating_collection array that is created in model instances
  # since marshalling that seems a bad idea.
  #
  class Unmarshallable
    instance_methods.each do |method|
      undef_method(method) unless method =~ /__.+__/ || method.to_sym == :respond_to? || method.to_sym == :object_id
    end

    class <<self
      def _load(dump)
        nil
      end
    end

    def initialize(underlying)
      @underlying = underlying
    end

    def method_missing(method, *args, &block)
      @underlying.__send__(method, *args, &block)
    end

    def respond_to?(method, include_private = false)
      super || @underlying.respond_to?(method, include_private)
    end

    def _dump(depth)
      Marshal.dump(nil)
    end
  end
end
