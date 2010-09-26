module Visage
  class Config

    class << self
      def use
        @configuration ||= {}
        yield @configuration
        nil
      end

      def method_missing(method, *args)
        if method.to_s[-1,1] == '='
          @configuration[method.to_s.tr('=','')] = *args
        else
          @configuration[method.to_s]
        end
      end

      def to_hash
        @configuration
      end
    end
  end
end
