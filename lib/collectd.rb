#!/usr/bin/env ruby

$: << File.expand_path(File.dirname(__FILE__))

require 'patches'

class Collectd

  class << self
    def rrddir
      @rrddir = "/var/lib/collectd/rrd"
    end

    def hosts
      Dir.glob("#{rrddir}/*").map {|e| e.split('/').last }.sort
    end

    def plugins(opts={})
      host = opts[:host] || '*'
      Dir.glob("#{rrddir}/#{host}/*").map {|e| e.split('/').last }.sort.uniq
    end

  end

end
