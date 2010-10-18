#!/usr/bin/env ruby

root = Pathname.new(File.dirname(__FILE__)).parent.parent
$: << root.join('lib')
require 'lib/visage-app/graph'
require 'lib/visage-app/patches'
require 'digest/md5'

module Visage
  class Profile
    attr_reader :options, :selected_hosts, :hosts, :selected_metrics, :metrics,
                :name, :errors

    def self.get(id)
      url = id.downcase.gsub(/[^\w]+/, "+")
      profiles = Visage::Config.profiles || {}
      profiles[url] ? self.new(profiles[url]) : nil
    end

    def self.all(opts={})
      sort = opts[:sort]
      profiles = Visage::Config.profiles || {}
      profiles = sort == "name" ? profiles.sort.map {|i| i.last } : profiles.values
      profiles.map { |prof| self.new(prof) }
    end

    def initialize(opts={})
      @options = opts
      @options[:url] = @options[:profile_name] ? @options[:profile_name].downcase.gsub(/[^\w]+/, "+") : nil
      @errors = {}

      # FIXME: this is nasty
      # FIXME: doesn't work if there's only one host
      # FIXME: add regex matching option
      if @options[:hosts].blank?
        @selected_hosts = []
        @hosts = Visage::Collectd::RRDs.hosts
      else
        @selected_hosts = Visage::Collectd::RRDs.hosts(:hosts => @options[:hosts])
        @hosts = Visage::Collectd::RRDs.hosts - @selected_hosts
      end

      if @options[:metrics].blank?
        @selected_metrics = []
        @metrics = Visage::Collectd::RRDs.metrics
      else
        @selected_metrics = Visage::Collectd::RRDs.metrics(:metrics => @options[:metrics])
        @metrics = Visage::Collectd::RRDs.metrics - @selected_metrics
      end
    end

    # Hashed based access to @options.
    def method_missing(method)
      @options[method]
    end

    def save
      if valid?
        # Construct record.
        attrs = { :hosts => @options[:hosts],
                  :metrics => @options[:metrics],
                  :profile_name => @options[:profile_name],
                  :url => @options[:profile_name].downcase.gsub(/[^\w]+/, "+") }

        # Save it.
        profiles = Visage::Config.profiles || {}
        profiles[attrs[:url]] = attrs

        Visage::Config::File.open('profiles.yaml') do |file|
          file << profiles.to_yaml
        end

        true
      else
        false
      end
    end

    def valid?
      valid_profile_name?
    end

    def graphs
      graphs = []

      hosts = Visage::Collectd::RRDs.hosts(:hosts => @options[:hosts])
      metrics = @options[:metrics]
      hosts.each do |host|
        attrs = {}
        globs = Visage::Collectd::RRDs.metrics(:host => host, :metrics => metrics)
        globs.each do |n|
          parts    = n.split('/')
          plugin   = parts[0]
          instance = parts[1]
          attrs[plugin] ||= []
          attrs[plugin] << instance
        end

        attrs.each_pair do |plugin, instances|
          graphs << Visage::Graph.new(:host => host,
                                      :plugin => plugin,
                                      :instances => instances)
        end
      end

      graphs
    end

    def private_id
      Digest::MD5.hexdigest("#{@options[:url]}\n")
    end

    private

    def valid_profile_name?
      if @options[:profile_name].blank?
        @errors[:profile_name] = "Profile name must not be blank."
        false
      else
        true
      end
    end

  end
end
