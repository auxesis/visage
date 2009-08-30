#!/usr/bin/env ruby

require 'RRDtool'
require 'yajl'

class CollectdJSON

  def initialize
    @basedir = "/var/lib/collectd/rrd"
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
    values = { 
      opts[:host] => {
        opts[:plugin] => {
          opts[:plugin_instance] => opts[:rrd].fetch(['AVERAGE'])
        }
      }
    }
    
    encoder = Yajl::Encoder.new
    encoder.encode(values)
  end

end
