module Visage
  class Data
    module Mock
      def self.included(base)
        base.extend(ClassMethods)
      end

      def json(opts={})
      end

      module ClassMethods
        def hosts(opts={})
        end

        def metrics(opts={})
        end
      end
    end
  end
end
