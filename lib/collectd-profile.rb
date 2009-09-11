#!/usr/bin/env ruby

require 'yaml'
require 'ostruct'

class CollectdProfile

  def initialize(opts={})
    @profile = opts[:profile]
  end

  class << self

    attr_accessor :profiles

    def get(id)
      id.gsub!(/\s+/, '+')
      OpenStruct.new(@profiles[id])
    end

    def all
      # here be ugliness
      profiles = @profiles.to_a.sort_by { |profile| 
        profile[1]["order"] 
      }.map { |profile| 
        OpenStruct.new(profile[1].merge({'url' => profile[0]}))
      }
    end

  end

end
