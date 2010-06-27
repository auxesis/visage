#!/usr/bin/env ruby

root = Pathname.new(File.dirname(__FILE__)).parent.parent
$: << root.join('lib')
require 'lib/visage/patches'

module Visage
  class Profile
    attr_reader :options, :selected_hosts, :hosts, :selected_metrics, :metrics,
                :name, :errors

    @@root = Pathname.new(File.dirname(__FILE__)).parent.parent.expand_path
    @@profiles_filename = @@root.join('lib/visage/config/profiles.yaml')

    def self.get(id)
      url = id.downcase.gsub(/[^\w]+/, "+")
      profiles = YAML::load_file(@@profiles_filename) || {}
      profiles[url] ? self.new(profiles[url]) : nil
    end

    def self.all
      profiles = YAML::load_file(@@profiles_filename) || {}
      profiles.values.map { |prof| self.new(prof) }
    end

    def initialize(opts={})
      @options = opts
      @options[:url] = @options[:profile_name] ? @options[:profile_name].downcase.gsub(/[^\w]+/, "+") : nil
      @errors = {}

      # FIXME: this is nasty
      # FIXME: doesn't work if there's only one host
      @selected_hosts = Visage::Collectd::RRDs.hosts(:hosts => @options[:hosts])
      if Visage::Collectd::RRDs.hosts == @selected_hosts
        @selected_hosts = []
        @hosts = Visage::Collectd::RRDs.hosts
      else
        @hosts = Visage::Collectd::RRDs.hosts - @selected_hosts
      end

      @selected_metrics = Visage::Collectd::RRDs.metrics(:metrics => @options[:metrics])
      if Visage::Collectd::RRDs.metrics == @selected_metrics
        @selected_metrics = []
        @metrics = Visage::Collectd::RRDs.metrics
      else
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
        profiles = YAML::load_file(@@profiles_filename) || {}
        profiles[attrs[:url]] = attrs

        File.open(@@profiles_filename, 'w') do |file|
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
