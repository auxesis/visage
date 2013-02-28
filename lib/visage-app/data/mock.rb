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
        hosts     = build_host_list(opts[:host])
        plugins   = build_plugin_list(opts[:plugin])
        instances = build_instances_list(opts[:instances])
        source    = 'value'

        finish    = parse_time(opts[:finish])
        start     = parse_time(opts[:start],  :default => (finish - 3600 || (Time.now - 3600).to_i))

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
              metric = (0..360).step(20).to_a.map {|i| Math.send(function, i) * 10 * index }[index ** 2..-1]
              metric = metric * ((finish - start) / 3600.0)

              structure[host][plugin][instance] ||= {}
              structure[host][plugin][instance][source] ||= {}
              structure[host][plugin][instance][source][:start]  ||= start
              structure[host][plugin][instance][source][:finish] ||= finish
              structure[host][plugin][instance][source][:data]   ||= metric
              structure[host][plugin][instance][source][:percentile_95]  ||= 95
              structure[host][plugin][instance][source][:percentile_50]  ||= 50
              structure[host][plugin][instance][source][:percentile_5]  ||= 5
            end
          end
        end

        encoder = Yajl::Encoder.new
        encoder.encode(structure)
      end

      private

      def build_host_list(hosts)
        hosts.split(',').map! do |host|
          if host =~ /\*/
            DATA[:hosts].find_all {|k| k =~ /#{host.gsub('*', '.*')}/ }
          else
            host
          end
        end.flatten
      end

      def build_plugin_list(plugins)
        plugins.split(',').map! do |plugin|
          if plugin =~ /\*/
            DATA[:metrics].keys.find_all {|k| k =~ /#{plugin.gsub('*', '.*')}/ }
          else
            plugin
          end
        end.flatten
      end

      def build_instances_list(instances)
        instances[1..-1] && instances[1..-1].split(',') || '*'
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
