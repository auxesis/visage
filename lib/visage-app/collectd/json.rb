#!/usr/bin/env ruby

@root = Pathname.new(File.dirname(__FILE__)).parent.parent.parent.expand_path
$: << @root.to_s
require 'lib/visage-app/patches'
require 'errand'
require 'yajl'

class Array
  def in_groups(number, fill_with = nil)
    raise "Error - in_groups of zero doesn't make sense" unless number > 0
    # size / number gives minor group size;
    # size % number gives how many objects need extra accomodation;
    # each group hold either division or division + 1 items.
    division = size / number
    modulo = size % number

    # create a new array avoiding dup
    groups = []
    start = 0

    number.times do |index|
      length = division + (modulo > 0 && modulo > index ? 1 : 0)
      padding = fill_with != false &&
        modulo > 0 && length == division ? 1 : 0
      groups << slice(start, length).concat([fill_with] * padding)
      start += length
    end

    if block_given?
      groups.each{|g| yield(g) }
    else
      groups
    end
  end

  def sum
    inject( nil ) { |sum,x| sum ? sum+x : x }
  end

  def mean
    if size > 0
      sum / size
    else
      nil
    end
  end

end

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

      private
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
            # FIXME: does this actually do anything?
            metric = metric.map do |datapoint|
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
