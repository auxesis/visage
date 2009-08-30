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

    rrdname = "#{@basedir}/#{host}/#{plugin}/#{plugin_instance}.rrd"
    rrd = RRDtool.new(rrdname)

    encode(opts.merge(:rrd => rrd))
  end

  def encode(opts={})
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
    
    encoder = Yajl::Encoder.new
    encoder.encode(values)
  end

  class << self
    attr_accessor :basedir

    def hosts
      Dir.glob("#{@basedir}/*").map {|e| e.split('/').last }.sort
    end

    def plugins(opts={})
      host = opts[:host] || '*'
      Dir.glob("#{@basedir}/#{host}/*").map {|e| e.split('/').last }.sort
    end

  end

end
