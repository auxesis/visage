#!/usr/bin/env ruby

module Visage
  class Types
    def self.all
      types = []

      filename = "/usr/share/collectd/types.db"
      file = File.new(filename)
      file.each_line do |line|
        next if line =~ /^#/
        next if line =~ /^\s*$/
        attrs   = {}
        spec    = line.strip.split(/\t+|,\s+/)
        dataset = spec.shift
        spec.each do |source|
          parts = source.split(':')
          types << { "dataset"    => dataset,
                     "datasource" => parts[0],
                     "type"       => parts[1],
                     "min"        => parts[2],
                     "max"        => parts[3] }
        end
      end

      types
    end

  end
end
