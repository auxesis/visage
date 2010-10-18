#!/usr/bin/env ruby

require 'digest/md5'

module Visage
  class Graph

    attr_accessor :host, :plugin, :instances

    def initialize(opts={})
      @host      = opts[:host]
      @plugin    = opts[:plugin]
      @instances = opts[:instances]
    end

    def id
      Digest::MD5.hexdigest("#{@host}-#{@plugin}-#{@instances}\n")
    end

  end
end
