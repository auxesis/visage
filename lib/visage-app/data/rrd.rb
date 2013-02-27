#!/usr/bin/env ruby

require 'errand'
require 'yajl'

# Exposes RRDs as JSON.
#
# A loose shim onto RRDtool/Errand, with some extra logic to normalise the data.
module Visage
  class Data
    module RRD
      # http://www.railstips.org/blog/archives/2009/05/15/include-vs-extend-in-ruby/
      def self.included(base)
        base.extend(ClassMethods)
      end

      # Entry point.
      def json(opts={})
        host        = opts[:host]
        plugin      = opts[:plugin]
        instances   = opts[:instances][/\w.*/]
        instances   = instances.blank? ? '*' : '{' + instances.split('/').join(',') + '}'
        percentiles = opts[:percentiles] !~ /^$|^false$/ ? true : false
        resolution  = opts[:resolution] || ""
        rrdglob     = "#{@rrddir}/#{host}/#{plugin}/#{instances}.rrd"
        finish      = parse_time(opts[:finish])
        start       = parse_time(opts[:start],  :default => (finish - 3600 || (Time.now - 3600).to_i))
        data        = []

        Dir.glob(rrdglob).map do |rrdname|
          parts         = rrdname.gsub(/#{@rrddir}\//, '').split('/')
          host_name     = parts[0]
          plugin_name   = parts[1]
          instance_name = File.basename(parts[2], '.rrd')

          if @collectdsock then
            socket = UNIXSocket.new(@collectdsock)
            socket.puts "FLUSH \"#{host_name}/#{plugin_name}/#{instance_name}\""
            socket.gets
            socket.close
          end

          if @rrdcachedsock then
            socket = UNIXSocket.new(@rrdcachedsock)
            socket.puts "FLUSH #{rrdname}"
            socket.gets
            socket.close
          end

          rrd           = Errand.new(:filename => rrdname)

          data << {  :plugin      => plugin_name, :instance => instance_name,
                     :host        => host_name,
                     :start       => start,
                     :finish      => finish,
                     :rrd         => rrd,
                     :percentiles => percentiles,
                     :resolution  => resolution}

        end

        encode(data)
      end

      private
      def percentile_of_array(samples, percentage)
        if samples
          samples.sort[ (samples.length.to_f * ( percentage.to_f / 100.to_f ) ).to_i - 1 ]
        else
          raise "I can't work out percentiles on a nil sample set"
        end
      end

      def downsample_array(samples, old_resolution, new_resolution)
        return samples unless samples.length > 0
        timer_start = Time.now
        new_samples = []
        if (new_resolution > 0) and (old_resolution > 0) and (new_resolution % old_resolution == 0)
          groups_of = samples.length / (new_resolution / old_resolution)
          return samples unless groups_of > 0
          samples.in_groups(groups_of, false) {|group|
            new_samples << group.compact.mean
          }
        else
          raise "downsample_array: cowardly refusing to downsample as old_resolution (#{old_resolution.to_s}) doesn't go into new_resolution (#{new_resolution.to_s}) evenly, or new_resolution or old_resolution are zero."
        end
        timer = Time.now - timer_start

        new_samples
      end

      # Attempt to structure the JSON reasonably sanely, so the consumer (i.e. a
      # browser) doesn't have to do a lot of computationally expensive work.
      def encode(datas)

        structure = {}
        datas.each do |data|

          start      = data[:start].to_i
          finish     = data[:finish].to_i
          resolution = data[:resolution].to_i || 0

          fetch    = data[:rrd].fetch(:function   => "AVERAGE",
                                      :start      => start.to_s,
                                      :finish     => finish.to_s)

          rrd_data = fetch[:data]
          percentiles = data[:percentiles]

          # A single rrd can have multiple data sets (multiple metrics within
          # the same file). Separate the metrics.
          rrd_data.each_pair do |source, metric|

            # Filter out NaNs and weirdly massive values so yajl doesn't choke
            metric = metric.map do |datapoint|
              if datapoint && datapoint.nan?
                @last_valid
              else
                @last_valid = datapoint
              end
            end

            # Last value is always wack. Remove it.
            metric   = metric[0...metric.length-1]
            host     = data[:host]
            plugin   = data[:plugin]
            instance = data[:instance]

            # only calculate percentiles if requested
            if percentiles
              timeperiod = finish.to_f - start.to_f
              interval = (timeperiod / metric.length.to_f).round
              resolution = 300
              if (interval < resolution) and (resolution > 0)
                metric_for_percentiles = downsample_array(metric, interval, resolution)
              else
                metric_for_percentiles = metric
              end
              metric_for_percentiles.compact!
              percentiles = false unless metric_for_percentiles.length > 0
            end

            if metric.length > 2000
              metric = downsample_array(metric, 1, metric.length / 1000)
            end

            structure[host] ||= {}
            structure[host][plugin] ||= {}
            structure[host][plugin][instance] ||= {}
            structure[host][plugin][instance][source] ||= {}
            structure[host][plugin][instance][source][:start]         ||= start
            structure[host][plugin][instance][source][:finish]        ||= finish
            structure[host][plugin][instance][source][:data]          ||= metric
            structure[host][plugin][instance][source][:percentile_95] ||= percentile_of_array(metric_for_percentiles, 95).round if percentiles
            structure[host][plugin][instance][source][:percentile_50] ||= percentile_of_array(metric_for_percentiles, 50).round if percentiles
            structure[host][plugin][instance][source][:percentile_5]  ||= percentile_of_array(metric_for_percentiles,  5).round if percentiles

          end
        end

        encoder = Yajl::Encoder.new
        encoder.encode(structure)
      end

      module ClassMethods
        attr_writer :rrddir

        def rrddir
          @rrddir ||= Visage::Config.rrddir
        end

        def types
          @types  ||= Visage::Config.types
        end

        def collectdsock
          @collectdsock ||= Visage::Config.collectdsock
        end

        def rrdcachedsock
          @rrdcachedsock ||= Visage::Config.rrdcachedsock
        end

        # Returns a list of hosts that match the supplied glob, or array of names.
        def hosts(opts={})
          hosts = opts[:hosts]
          case hosts
          when String
            glob = "{#{hosts}}"
          when Array
            glob = "{#{opts[:hosts].join(',')}}"
          else
            glob = "*"
          end

          Dir.glob("#{rrddir}/#{glob}").map {|e| e.split('/').last }.sort.uniq
        end

        def metrics(opts={})
          selected_hosts = hosts(opts)

          metrics = opts[:metrics]
          case metrics
          when String && /,/
            metric_glob = "{#{metrics}}"
          when Array
            metric_glob = "{#{opts[:metrics].join(',')}}"
          else
            metric_glob = "*/*"
          end

          dametrics = selected_hosts.map { |host|
            Dir.glob("#{rrddir}/#{host}/#{metric_glob}.rrd").map {|filename|
              filename[/#{rrddir}\/#{host}\/(.*)\.rrd/, 1]
            }
          }
          if (dametrics.length) == 1
            dametrics.first
          else
            dametrics.reduce(:|)
          end
        end
      end # module ClassMethods
    end # module RRD
  end # class Data
end # module Visage
