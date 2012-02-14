#!/usr/bin/env ruby

$: << File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..'))

require 'lib/visage-app/patches'

module Visage
  module Collectd
    class RRDs

      class << self
        def rrddir
          @rrddir ||= Visage::Config.rrddir
        end

        # Returns a list of hosts that match the supplied glob, or array of names.
        def hosts(opts={})
          hosts = opts[:hosts]
          case hosts
          when String && /,/
            glob = "{#{hosts}}"
          when Array
            glob = "{#{opts[:hosts].join(',')}}"
          when String
            glob = "#{hosts}"
          else
            glob = "*"
          end

          Dir.glob("#{rrddir}/#{glob}").map {|e| e.split('/').last }.sort.uniq
        end

        def metrics(opts={})
          selected_hosts = hosts(opts)

          metrics = opts[:metrics]
          case metrics
          when String && /,/
            metric_glob = "{#{metrics}}"
          when Array
            metric_glob = "{#{opts[:metrics].join(',')}}"
          else
            metric_glob = "*/*"
          end

          selected_hosts.map { |host|
            Dir.glob("#{rrddir}/#{host}/#{metric_glob}.rrd").map {|filename|
              filename[/#{rrddir}\/#{host}\/(.*)\.rrd/, 1]
            }
          }.reduce(:&)
          #else
          #  Dir.glob("#{rrddir}/#{host_glob}/#{glob}.rrd").map {|e| e.split('/')[-2..-1].join('/').gsub(/\.rrd$/, '')}.sort.uniq
          #end
        end

      end

    end
  end
end
