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
      if found = @profiles.find {|p| p[1]["splatpart"] == id }
        OpenStruct.new(found[1])
      else
        nil
      end
    end

    def all
      # here be ugliness
      profiles = @profiles.to_a.sort_by { |profile| 
        profile[1]["order"] 
      }.map { |profile| 
        OpenStruct.new(profile[1].merge({'name' => profile[0]}))
      }
    end

  end

end
