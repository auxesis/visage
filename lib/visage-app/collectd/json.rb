#!/usr/bin/env ruby

@root = Pathname.new(File.dirname(__FILE__)).parent.parent.parent.expand_path
$: << @root.to_s
require 'lib/visage-app/patches'
require 'errand'
require 'yajl'

class Array
  def in_groups(number, fill_with = nil)
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
        percentiles = opts[:percentile] == "true" ? true : false
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
        samples.sort[ (samples.length.to_f * ( percentage.to_f / 100.to_f ) ).to_i - 1 ]
      end

      def downsample_array(samples, old_resolution, new_resolution)
        timer_start = Time.now
        p "in downsample_array(samples, old_resolution=#{old_resolution}, new_resolution=#{new_resolution}, new_resolution / old_resolution = " + (new_resolution / old_resolution).to_s
        new_samples = []
        if (new_resolution > 0) and (old_resolution > 0) and (new_resolution % old_resolution == 0)
          samples.in_groups(samples.length / (new_resolution / old_resolution), false) {|group|
            new_samples << group.compact.mean
          }
        else
          raise "downsample_array: cowardly refusing to downsample as old_resolution (#{old_resolution.to_s}) doesn't go into new_resolution (#{new_resolution.to_s}) evenly, or new_resolution or old_resolution are zero."
        end
        timer = Time.now - timer_start
        p "downsampled from #{samples.length.to_s} to #{new_samples.length.to_s} in #{timer.to_s}"

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

            # if resolution > 0
            # a specific resolution has been requested, so we need to
            # a) ensure the start and finish times are multiples of
            # resolution, AND b) both start and finish are within the
            # desired RRA, FFS.
            # http://oss.oetiker.ch/rrdtool/doc/rrdfetch.en.html
            # So, we need to inspect the RRAs to check the start and
            # end fall within the RRA we want. so something like this:
            #
            # rrdinfo - extract global step, and pdp_per_row's of each data series
            # rrdfirst & rrdlast - extract unix timestamps for first and last records in each data
            # series
            # work out start and finish timestamps that fall within the rrdfirst and rrdlast values
            # for the desired rra, and that fall within the timespan requested by the visage client
            # rrdfetch - specifying the resolution and start and finish timestamps as per above
            #
            # OR alternatively let RRD throw back whatever highest res data it can find for the
            # requested time range and downsample in ruby

            #xyz = data[:rrd].info.keys.grep(/^ds\[/).map { |ds| ds[3..-1].split(']').first}.uniq
            #p "rrdinfo: "
            #puts data[:rrd].info.inspect
            #fetch    = data[:rrd].fetch(:function   => "AVERAGE",
            #                            :start      => start.to_s,
            #                            :finish     => finish.to_s,
            #                            :resolution => resolution.to_s)

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


            #if percentiles
              timeperiod = finish.to_f - start.to_f
              interval = (timeperiod / metric.length.to_f).round
              p "timeperiod: #{timeperiod}, interval: #{interval}"
              metric_resolution = interval
              resolution = 300
              if (metric_resolution < resolution) and (resolution > 0)
                metric = downsample_array(metric, metric_resolution, resolution)
              end
              p "metric length: #{metric.length.to_s}"
              metric_no_nils = metric.compact
              p "metric_no_nils length: #{metric_no_nils.length.to_s}"
              p "95e for #{source}: " + percentile_of_array(metric_no_nils, 95).to_s
            #end

            if metric.length > 2000
              metric = downsample_array(metric, 1, metric.length / 1000)
              p "metric length after downsampling for viewing: #{metric.length.to_s}"
            end

            structure[host] ||= {}
            structure[host][plugin] ||= {}
            structure[host][plugin][instance] ||= {}
            structure[host][plugin][instance][source] ||= {}
            structure[host][plugin][instance][source][:start]         ||= start
            structure[host][plugin][instance][source][:finish]        ||= finish
            structure[host][plugin][instance][source][:data]          ||= metric
            structure[host][plugin][instance][source][:percentile_95] ||= percentile_of_array(metric_no_nils, 95) #if percentiles
            structure[host][plugin][instance][source][:percentile_50] ||= percentile_of_array(metric_no_nils, 50) #if percentiles
            structure[host][plugin][instance][source][:percentile_5]  ||= percentile_of_array(metric_no_nils,  5) #if percentiles

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
