#!/usr/bin/env ruby

require 'RRDtool'
require 'yajl'

class CollectdJSON

  def initialize(opts={})
    @basedir = opts[:basedir] || "/var/lib/collectd/rrd"
  end

  def json(opts={})
    host            = opts[:host]
    plugin          = opts[:plugin]
    plugin_instance = opts[:plugin_instance]
    @colors         = opts[:plugin_colors]

    if plugin_instance
      rrdname = "#{@basedir}/#{host}/#{plugin}/#{plugin_instance}.rrd"
      rrd = RRDtool.new(rrdname)

      encode_single(opts.merge(:rrd => rrd))
    else
      rrds = {}
      rrdglob = "#{@basedir}/#{host}/#{plugin}/*.rrd"
      Dir.glob(rrdglob).map do |rrdname|
        rrds[File.basename(rrdname, '.rrd')] = RRDtool.new(rrdname)
      end

      encode_multiple(opts.merge(:rrds => rrds))
    end
  end

  def encode_multiple(opts={})
    opts[:start] ||= (Time.now - 3600).to_i
    opts[:end]   ||= (Time.now).to_i
    opts[:start].to_s.gsub!(/\.\d+$/,'')
    opts[:end].to_s.gsub!(/\.\d+$/,'')

    values = { opts[:host] => { opts[:plugin] => {} } }
   
    opts[:rrds].each_pair do |name, rrd|
      plugin_instance = rrd.fetch(['AVERAGE', '--start', opts[:start], '--end', opts[:end]])
      plugin_instance << color_for(:host => opts[:host], :plugin => opts[:plugin], :plugin_instance => name)
      values[opts[:host]][opts[:plugin]].merge!({ name => plugin_instance })
    end

    encoder = Yajl::Encoder.new
    encoder.encode(values)
  end

  def encode_single(opts={})
    opts[:start] ||= (Time.now - 3600).to_i
    opts[:end]   ||= (Time.now).to_i
    opts[:start].to_s.gsub!(/\.\d+$/,'')
    opts[:end].to_s.gsub!(/\.\d+$/,'')

    values = { 
      opts[:host] => {
        opts[:plugin] => {
          opts[:plugin_instance] => opts[:rrd].fetch(['AVERAGE', '--start', opts[:start], '--end', opts[:end]])
        }
      }
    }
    values[opts[:host]][opts[:plugin]][opts[:plugin_instance]] << color_for(:host => opts[:host], :plugin => opts[:plugin], :plugin_instance => opts[:plugin_instance])
    
    encoder = Yajl::Encoder.new
    encoder.encode(values)
  end

  def color_for(opts={})
    case 
    when @colors[opts[:plugin]] && @colors[opts[:plugin]][opts[:plugin_instance]]
      color = @colors[opts[:plugin]][opts[:plugin_instance]]
      color ? color : random_color

    when opts[:plugin_instance] =~ /\-/
      base_plugin_instance = opts[:plugin_instance].split('-').first
      if plugin_colors = @colors[opts[:plugin]]
        color = plugin_colors[base_plugin_instance]
        color ? color : random_color
      else
        random_color
      end

    when opts[:plugin] =~ /\-/
      base_plugin = opts[:plugin].split('-').first
      if plugin_colors = @colors[base_plugin]
        color = plugin_colors[opts[:plugin_instance]]
      else
        random_color
      end

    else
      random_color
    end
  end

  def random_color
    
    "#000"
  end

  class << self
    attr_accessor :basedir

    def hosts
      if @basedir
        Dir.glob("#{@basedir}/*").map {|e| e.split('/').last }.sort
      else
        ['You need to specify <strong>rrddir</strong> in config.yaml!']
      end
    end

    def plugins(opts={})
      host = opts[:host] || '*'
      Dir.glob("#{@basedir}/#{host}/*").map {|e| e.split('/').last }.sort
    end

  end

end
