#!/usr/bin/env ruby

$: << File.expand_path(File.dirname(__FILE__))

require 'patches'

class Collectd

  class << self
    def rrddir
      @rrddir = "/var/lib/collectd/rrd"
    end

    def hosts(opts={})
      case 
      when opts[:hosts].blank?
        glob = "*"
      when opts[:hosts] =~ /,/
        glob = "{#{opts[:hosts].strip.gsub(/\s*/, '').gsub(/,$/, '')}}"
      else
        glob = opts[:hosts]
      end

      Dir.glob("#{rrddir}/#{glob}").map {|e| e.split('/').last }.sort.uniq
    end

    def metrics(opts={})
      case 
      when opts[:metrics].blank?
        glob = "*/*"
      when opts[:metrics] =~ /,/
        puts "\n" * 4
        glob = "{" + opts[:metrics].split(/\s*,\s*/).map { |m| 
          m =~ /\// ? m : ["*/#{m}", "#{m}/*"]
        }.join(',').gsub(/,$/, '') + "}"
      when opts[:metrics] !~ /\//
        glob = "#{opts[:metrics]}/#{opts[:metrics]}"
      else
        glob = opts[:metrics]
      end

      Dir.glob("#{rrddir}/*/#{glob}.rrd").map {|e| e.split('/')[-2..-1].join('/').gsub(/\.rrd$/, '')}.sort.uniq
    end

  end

end
