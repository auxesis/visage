#!/usr/bin/env ruby

$: << File.expand_path(File.dirname(__FILE__))

require 'errand'
require 'yajl'
require 'patches/string'

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
    plugin_instances = opts[:plugin_instances]
    @colors          = opts[:plugin_colors]

      rrds = {}
      rrdglob = "#{@rrddir}/#{host}/#{plugin}/#{ plugin_instances=="" ? '*' : '{' + plugin_instances.split('/').join(',') + '}' }.rrd"
      Dir.glob(rrdglob).map do |rrdname|
        rrds[File.basename(rrdname, '.rrd')] = RRDtool.new(rrdname)
      end

    encode(opts.merge(:rrds => rrds))
  end

  # Attempt to structure the JSON reasonably sanely, so the consumer doesn't
  # have to do a lot of computationally expensive work when processing it.
  def encode(opts={})
    opts[:start] ||= (Time.now - 3600).to_i
    opts[:end]   ||= (Time.now).to_i

    values = { opts[:host] => { opts[:plugin] => {} } }
   
    opts[:rrds].each_pair do |name, rrd|
      rrd_data = rrd.fetch(:function => "AVERAGE", :start => opts[:start], :end => opts[:end])
        plugin_instance = {:start => rrd_data[:start], :finish => rrd_data[:finish], :data => rrd_data[:data]}
        
        # filter out NaNs, so yajl doesn't choke
        
        plugin_instance[:data].each_pair do |source, points|
          points.map! do |datapoint|
            (!datapoint || datapoint.nan?) ? 0.0 : datapoint
          end
        end

      # append the line color onto the end of the data set
      plugin_instance[:data].each_key do |source|
        plugin_instance[:colors] = color_for(:host => opts[:host], :plugin => opts[:plugin], :plugin_instance => name)
      end
      values[opts[:host]][opts[:plugin]].merge!({ name => plugin_instance})
    end

    encoder = Yajl::Encoder.new
    encoder.encode(values)
  end

  # We append the recommended line color onto data set, so the javascript
  # doesn't try and have to work it out. This lets us use all sorts of funky
  # fallback logic when determining what colours should be used.
  def color_for(opts={})
    case 
    when @colors[opts[:plugin]] && @colors[opts[:plugin]][opts[:plugin_instance]]
      color = @colors[opts[:plugin]][opts[:plugin_instance]]
      color ? color : fallback_color

    when opts[:plugin] =~ /\-/ && opts[:plugin_instance] =~ /\-/
      base_plugin = opts[:plugin].split('-').first
      base_plugin_instance = opts[:plugin_instance].split('-').first
      
      if plugin_colors = @colors[base_plugin]
        color = plugin_colors[opts[:plugin_instance]]
        color ? color : fallback_color
      elsif plugin_colors = @colors[opts[:plugin]]
        color = plugin_colors[base_plugin_instance]
        color ? color : fallback_color
      else
        fallback_color
      end

    when opts[:plugin_instance] =~ /\-/
      base_plugin_instance = opts[:plugin_instance].split('-').first
      if plugin_colors = @colors[opts[:plugin]]
        color = plugin_colors[base_plugin_instance]
        color ? color : fallback_color
      else
        fallback_color
      end

    when opts[:plugin] =~ /\-/
      base_plugin = opts[:plugin].split('-').first
      if plugin_colors = @colors[base_plugin]
        color = plugin_colors[opts[:plugin_instance]]
      else
        fallback_color
      end

    else
      fallback_color
    end
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
