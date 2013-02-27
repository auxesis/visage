module Visage
  class Data
    module Mock
      DATA = {
        :hosts   => %w(localhost.localdomain ubuntu.localdomain app-01.example.org),
        :metrics => {
          'cpu-0'   => %w(cpu-user cpu-idle cpu-steal cpu-system cpu-wait),
          'cpu-1'   => %w(cpu-user cpu-idle cpu-steal cpu-system cpu-wait),
          'df'      => %w(df-root df-dev-shm),
          'entropy' => %w(entropy),
          'load'    => %w(shortterm midterm longterm),
          'memory'  => %w(memory-free memory-used memory-cached memory-buffered),
          'swap'    => %w(swap-cached swap-free swap-used),
        }
      }

      def self.included(base)
        base.extend(ClassMethods)
      end

      def json(opts={})
        # setup variables
        hosts     = opts[:host].split(',')
        plugins   = opts[:plugin].split(',')
        instances = opts[:instances][1..-1] && opts[:instances][1..-1].split(',') || '*'
        source    = 'value'

        start     = (opts[:start] || (Time.now - 3600).to_i).to_i
        finish    = (opts[:finish] || (Time.now).to_i).to_i
        structure = {}
        functions = [:sin, :cos, :cbrt,] * 10

        # Build data structures
        hosts.each do |host|
          structure[host] ||= {}

          plugins.each do |plugin|
            structure[host][plugin] ||= {}

            instances = DATA[:metrics][plugin] if instances == '*'
            instances.each_with_index do |instance, index|
              function = functions[index]
              metric = opts[:metric] || (0..360).to_a.map {|i| Math.send(function, i) * 10 * index }[index ** 2..-1]

              structure[host][plugin][instance] ||= {}
              structure[host][plugin][instance][source] ||= {}
              structure[host][plugin][instance][source][:start]  ||= start
              structure[host][plugin][instance][source][:finish] ||= finish
              structure[host][plugin][instance][source][:data]   ||= metric
            end
          end
        end

        encoder = Yajl::Encoder.new
        encoder.encode(structure)
      end

      module ClassMethods
        def hosts(opts={})
          DATA[:hosts]
        end

        def metrics(opts={})
          DATA[:metrics].map { |plugin, instances|
            instances.map { |instance|
              "#{plugin}/#{instance}"
            }
          }.flatten
        end
      end
    end
  end
end
