#!/usr/bin/env ruby

require 'RRDtool'
require 'yajl'

class CollectdJSON

  def initialize(opts={})
    @rrddir = opts[:rrddir] || "/var/lib/collectd/rrd"
    @fallback_colors = opts[:fallback_colors] || {}
    @used_fallbacks = []
  end

  def json(opts={})
    host            = opts[:host]
    plugin          = opts[:plugin]
    plugin_instance = opts[:plugin_instance]
    @colors         = opts[:plugin_colors]

      rrds = {}
      rrdglob = "#{@rrddir}/#{host}/#{plugin}/#{plugin_instance || '*'}.rrd"
      Dir.glob(rrdglob).map do |rrdname|
        rrds[File.basename(rrdname, '.rrd')] = RRDtool.new(rrdname)
      end

      encode(opts.merge(:rrds => rrds))
  end

  def encode(opts={})
    opts[:start] ||= (Time.now - 3600).to_i
    opts[:end]   ||= (Time.now).to_i
    opts[:start].to_s.gsub!(/\.\d+$/,'')
    opts[:end].to_s.gsub!(/\.\d+$/,'')

    values = { opts[:host] => { opts[:plugin] => {} } }
   
    opts[:rrds].each_pair do |name, rrd|
      plugin_instance = rrd.fetch(['AVERAGE', '--start', opts[:start], '--end', opts[:end]])
   
      # filter out NaNs, so yajl doesn't choke
      plugin_instance[3].each do |datasets|
        datasets.map! do |datapoint|
          datapoint.nan? ? 0.0 : datapoint
        end
      end

      plugin_instance.last.last.size.times do
        plugin_instance << color_for(:host => opts[:host], :plugin => opts[:plugin], :plugin_instance => name)
      end
      values[opts[:host]][opts[:plugin]].merge!({ name => plugin_instance })
    end

    encoder = Yajl::Encoder.new
    encoder.encode(values)
  end

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
    @used_fallbacks << fallback
    fallback[1]['color'] || "#000"
  end

  class << self
    attr_accessor :rrddir

    def hosts
      if @rrddir
        Dir.glob("#{@rrddir}/*").map {|e| e.split('/').last }.sort
      else
        ['You need to specify <strong>rrddir</strong> in config/init.rb!']
      end
    end

    def plugins(opts={})
      host = opts[:host] || '*'
      Dir.glob("#{@rrddir}/#{host}/*").map {|e| e.split('/').last }.sort
    end

  end

end
