#!/usr/bin/env ruby

module Visage
  class Types
    attr_reader :types

    def initialize(opts={})
      @filename = opts[:filename] || "/usr/share/collectd/types.db"
      @types    = []
      build
    end

    def to_json
      @types.to_json
    end

    private
    def build
      file = File.new(@filename)
      file.each_line do |line|
        next if line =~ /^#/
        next if line =~ /^\s*$/
        attrs   = {}
        spec    = line.strip.split(/\t+|,\s+/)
        dataset = spec.shift
        spec.each do |source|
          parts = source.split(':')
          @types << { "dataset"    => dataset,
                      "datasource" => parts[0],
                      "type"       => parts[1],
                      "min"        => parts[2],
                      "max"        => parts[3] }
        end
      end
    end
  end
end
