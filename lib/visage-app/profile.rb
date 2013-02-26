#!/usr/bin/env ruby

root = Pathname.new(File.dirname(__FILE__)).parent.parent
$: << root.join('lib').to_s
require 'visage-app/graph'
require 'visage-app/patches'
require 'digest/md5'

module Visage
  class Profile
    attr_reader :options, :errors

    def self.load
      Visage::Config::File.load('profiles.yaml', :create => true, :ignore_bundled => true) || {}
    end

    def self.get(id)
      url = id.downcase.gsub(/[^\w]+/, "+")
      profiles = self.load
      profiles[url] ? self.new(profiles[url]) : nil
    end

    def self.all(opts={})
      sort      = opts.delete(:sort)
      anonymous = opts.delete(:anonymous)
      all       = self.load

      profiles = all.find_all { |id, attrs| attrs[:anonymous] == anonymous }
      profiles = profiles.sort_by {|id, attrs| attrs[:created_at] }
      profiles.reverse! if sort == 'ascending'

      # FIXME - to sort by creation time we need to save creation time on each profile
      profiles.map { |id, attrs| self.new(attrs) }
    end

    def initialize(opts={})
      @options = opts
      @errors  = {}
    end

    # Hashed based access to @options.
    def method_missing(method)
      @options[method] || @options[method.to_s]
    end

    def save
      if valid?
        # Construct record.
        if anonymous
          attrs = {
            :graphs       => graphs,
            :timeframe    => timeframe,
            :url          => SecureRandom.hex,
            :created_at   => Time.now,
            :anonymous    => true
          }
        else
          attrs = {
            :graphs       => graphs,
            :timeframe    => timeframe,
            :profile_name => profile_name,
            :url          => profile_name.downcase.gsub(/[^\w]+/, "+"),
            :created_at   => Time.now,
            :anonymous    => false
          }
        end

        # Save it.
        profiles = self.class.load
        profiles[attrs[:url]] = attrs

        Visage::Config::File.open('profiles.yaml') do |file|
          file.truncate(0)
          file << profiles.to_yaml
        end

        @options = attrs # load up saved attributes

        true
      else
        false
      end
    end

    def valid?
      if anonymous
        true
      else
        valid_profile_name?
      end
    end

    def to_json
      @options.to_json
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
