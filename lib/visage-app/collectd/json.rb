#!/usr/bin/env ruby

@root = Pathname.new(File.dirname(__FILE__)).parent.parent.parent.expand_path
$: << @root.to_s
require 'lib/visage-app/patches'
require 'errand'
require 'yajl'
require 'socket'

# Exposes RRDs as JSON.
#
# A loose shim onto RRDtool, with some extra logic to normalise the data.
#
module Visage
  module Collectd
    class JSON

      def initialize(opts={})
        @rrddir = opts[:rrddir] || Visage::Collectd::JSON.rrddir
        @types  = opts[:types]  || Visage::Collectd::JSON.types
        @unixsock = opts[:unixsock] || false
      end

      def parse_time(time, opts={})
        case
        when time && time.index('.')
          time.split('.').first.to_i
        when time
          time.to_i
        else
         opts[:default] || Time.now.to_i
        end
      end

      # Entry point.
      def json(opts={})
        host      = opts[:host]
        plugin    = opts[:plugin]
        instances = opts[:instances][/\w.*/]
        seperate_instances = instances.split(',')
        instances = instances.blank? ? '*' : '{' + instances.split('/').join(',') + '}'
        rrdglob   = "#{@rrddir}/#{host}/#{plugin}/#{instances}.rrd"
        finish    = parse_time(opts[:finish])
        start     = parse_time(opts[:start],  :default => (finish - 3600 || (Time.now - 3600).to_i))
        data      = []

        if @unixsock then 
          ids = ""
          seperate_instances.each do |identifier|
            ids = ids+" identifier=\"#{host}/#{plugin}/#{identifier}\""
          end

          socket = UNIXSocket.new(@unixsock)
          socket.puts "FLUSH #{ids}"
          line = socket.gets
          socket.close
        end

        Dir.glob(rrdglob).map do |rrdname|
          parts         = rrdname.gsub(/#{@rrddir}\//, '').split('/')
          host_name     = parts[0]
          plugin_name   = parts[1]
          instance_name = File.basename(parts[2], '.rrd')
          rrd           = Errand.new(:filename => rrdname)

          data << {  :plugin => plugin_name, :instance => instance_name,
                     :host   => host_name,
                     :start  => start,
                     :finish => finish,
                     :rrd    => rrd }
        end

        encode(data)
      end

      private
      # Attempt to structure the JSON reasonably sanely, so the consumer (i.e. a
      # browser) doesn't have to do a lot of computationally expensive work.
      def encode(datas)

        structure = {}
        datas.each do |data|
          fetch    = data[:rrd].fetch(:function => "AVERAGE",
                                      :start    => data[:start],
                                      :finish   => data[:finish])
          rrd_data = fetch[:data]

          # A single rrd can have multiple data sets (multiple metrics within
          # the same file). Separate the metrics.
          rrd_data.each_pair do |source, metric|

            # Filter out NaNs and weirdly massive values so yajl doesn't choke
            metric.map! do |datapoint|
              case
              when datapoint && datapoint.nan?
                @tripped = true
                @last_valid
              when @tripped
                @last_valid
              else
                @last_valid = datapoint
              end
            end

            # Last value is always wack. Set to 0, so the timescale isn't off by 1.
            metric[-1] = 0.0
            host     = data[:host]
            plugin   = data[:plugin]
            instance = data[:instance]
            start    = data[:start].to_i
            finish   = data[:finish].to_i

            structure[host] ||= {}
            structure[host][plugin] ||= {}
            structure[host][plugin][instance] ||= {}
            structure[host][plugin][instance][source] ||= {}
            structure[host][plugin][instance][source][:start]  ||= start
            structure[host][plugin][instance][source][:finish] ||= finish
            structure[host][plugin][instance][source][:data]   ||= metric

          end
        end

        encoder = Yajl::Encoder.new
        encoder.encode(structure)
      end

      class << self
        attr_writer :rrddir

        def rrddir
          @rrddir ||= Visage::Config.rrddir
        end

        def types
          @types  ||= Visage::Config.types
        end

        def hosts
          if @rrddir
            Dir.glob("#{@rrddir}/*").map {|e| e.split('/').last }.sort
          end
        end

        def plugins(opts={})
          host = opts[:host] || '*'
          Dir.glob("#{@rrddir}/#{host}/*").map {|e| e.split('/').last }.sort
        end

      end

    end # class JSON
  end # module Collectd
end # module Visage
