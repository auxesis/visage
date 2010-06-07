#!/usr/bin/env ruby

$: << File.expand_path(File.dirname(__FILE__))

require 'errand'
require 'yajl'
require 'patches'

# Exposes RRDs as JSON. 
#
# A loose shim onto RRDtool, with some extra logic to normalise the data.
# Also provides a recommended color for rendering the data in a line graph.
#
class CollectdJSON

  def initialize(opts={})
    @rrddir = opts[:rrddir] || CollectdJSON.rrddir
    @fallback_colors = opts[:fallback_colors] || {}
    @used_fallbacks = []
  end

  # Entry point.
  def json(opts={})
    host             = opts[:host]
    plugin           = opts[:plugin]
    plugin_instances = opts[:plugin_instances][/\w.*/]
    instances        = plugin_instances.blank? ? '*' : '{' + plugin_instances.split('/').join(',') + '}'
    @colors          = opts[:plugin_colors]
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
        
        # filter out NaNs, so yajl doesn't choke
        metric.map! do |datapoint|
          (!datapoint || datapoint.nan?) ? 0.0 : datapoint
        end

        color = color_for(:host => data[:host], 
                          :plugin => data[:plugin], 
                          :instance => data[:instance],
                          :metric => source)

        structure[data[:host]] ||= {}
        structure[data[:host]][data[:plugin]] ||= {}
        structure[data[:host]][data[:plugin]][data[:instance]] ||= {}
        structure[data[:host]][data[:plugin]][data[:instance]][source] ||= {}
        structure[data[:host]][data[:plugin]][data[:instance]][source][:start]  ||= data[:start]
        structure[data[:host]][data[:plugin]][data[:instance]][source][:finish] ||= data[:finish]
        structure[data[:host]][data[:plugin]][data[:instance]][source][:data]   ||= metric
        structure[data[:host]][data[:plugin]][data[:instance]][source][:color]  ||= color
      end
    end

    encoder = Yajl::Encoder.new
    encoder.encode(structure)
  end

  # We append the recommended line color onto data set, so the javascript
  # doesn't try and have to work it out. This lets us use all sorts of funky
  # fallback logic when determining what colours should be used.
  def color_for(opts={})

    plugin   = opts[:plugin]
    instance = opts[:instance]
    metric   = opts[:metric]

    return fallback_color unless plugin
    return color_for(opts.merge(:plugin => plugin[/(.+)-.+$/, 1])) unless @colors[plugin]
    return color_for(opts.merge(:instance => instance[/(.+)-.+$/, 1])) unless @colors[plugin][instance]
    return @colors[plugin][instance][metric] if @colors[plugin][instance]
    return fallback_color
  end

  def fallback_color
    fallbacks = @fallback_colors.to_a.sort_by {|pair| pair[1]['fallback_order'] }
    fallback = fallbacks.find { |color| !@used_fallbacks.include?(color) }
    unless fallback
      @used_fallbacks = []
      fallback = fallbacks.find { |color| !@used_fallbacks.include?(color) }
    end
    @used_fallbacks << fallback
    fallback[1]['color'] || "#000"
  end

  class << self
    attr_writer :rrddir

    def rrddir
      @rrddir || @rrddir = "/var/lib/collectd/rrd"
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
