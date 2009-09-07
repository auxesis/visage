#!/usr/bin/env ruby

require 'yaml'
require 'ostruct'

class CollectdProfile

  def initialize(opts={})
    @profile = opts[:profile]
  end

  class << self

    attr_accessor :config_filename

    def get(id)
      id.gsub!(/\s+/, '+')
      if @config_filename && File.exists?(@config_filename)
        config = YAML::load(File.read(@config_filename))
        OpenStruct.new(config['profiles'][id])
      end
    end

    def all
      if @config_filename && File.exists?(@config_filename)
        config = YAML::load(File.read(@config_filename))
        # here be ugliness
        profiles = config['profiles'].to_a.sort_by { |profile| 
          profile[1]["order"] 
        }.map { |profile| 
          OpenStruct.new(profile[1].merge({'url' => profile[0]}))
        }
      end
    end

  end

end
