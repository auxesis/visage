#!/usr/bin/env ruby

@root = Pathname.new(File.dirname(__FILE__)).parent.parent.parent.expand_path
$: << @root.to_s
require 'lib/visage/patches'
require 'errand'
require 'yajl'

# Exposes RRDs as JSON.
#
# A loose shim onto RRDtool, with some extra logic to normalise the data.
#
class CollectdJSON

  def initialize(opts={})
    @rrddir = opts[:rrddir] || CollectdJSON.rrddir
  end

  # Entry point.
  def json(opts={})
    host             = opts[:host]
    plugin           = opts[:plugin]
    plugin_instances = opts[:plugin_instances][/\w.*/]
    instances        = plugin_instances.blank? ? '*' : '{' + plugin_instances.split('/').join(',') + '}'
    @plugin_names = []

    rrdglob = "#{@rrddir}/#{host}/#{plugin}/#{instances}.rrd"
    plugin_offset = @rrddir.size + 1 + host.size + 1

    data = []

    Dir.glob(rrdglob).map do |rrdname|
      parts         = rrdname.gsub(/#{@rrddir}\//, '').split('/')
      host          = parts[0]
      plugin_name   = parts[1]
      instance_name = parts[2].split('.').first
      rrd = Errand.new(:filename => rrdname)

      data << { :plugin  => plugin_name, :instance => instance_name,
                 :host   => host,
                 :start  => opts[:start] || (Time.now - 3600).to_i,
                 :finish => opts[:finish] || Time.now.to_i,
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
      fetch = data[:rrd].fetch(:function => "AVERAGE",
                                  :start => data[:start],
                                  :finish => data[:finish])
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

        metric[-1] = 0.0

        structure[data[:host]] ||= {}
        structure[data[:host]][data[:plugin]] ||= {}
        structure[data[:host]][data[:plugin]][data[:instance]] ||= {}
        structure[data[:host]][data[:plugin]][data[:instance]][source] ||= {}
        structure[data[:host]][data[:plugin]][data[:instance]][source][:start]  ||= data[:start]
        structure[data[:host]][data[:plugin]][data[:instance]][source][:finish] ||= data[:finish]
        structure[data[:host]][data[:plugin]][data[:instance]][source][:data]   ||= metric
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

end
