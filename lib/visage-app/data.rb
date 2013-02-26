#!/usr/bin/env ruby

@root = Pathname.new(File.dirname(__FILE__)).parent.parent.expand_path
$: << @root.to_s
require 'visage-app/patches'
require 'errand'
require 'yajl'

# Proxy for the various Visage data backends.
#
# Mixes in a backend when you call `Visage::Data.backend`.
# e.g. `Visage::Data.backend = 'RRD'
#
module Visage
  class Data
    attr_accessor :options

    def initialize(opts={})
      @options = opts

      # Create shortcut instance variables for all of the options passed in.
      #
      # This makes looking up instance variables within each of the backends
      # significantly easier, e.g. rather than doing @options[:rrddir] in every
      # method, we create an @rrddir instance variable as a shortcut.
      @options.each_pair do |key, value|
        instance_variable_set("@#{key}", value)
      end
    end

    # Sets the data backend to use on subsequent requests.
    #
    # Currently supported backends are RRD and Mock.
    def self.backend=(backend)
      # Dynamically load up all the backends we know about.
      backends = Dir.glob(File.join(File.dirname(__FILE__), 'data', '*.rb'))
      backends.each { |b| require(b) }

      # Determine the module name, and include it into Visage::Data.
      #
      # Uses method documented at http://ithaca.arpinum.org/2010/07/29/ruby-dynamic-includes.html
      module_name = Visage::Data.const_get(backend)
      self.send(:include, module_name)
    end
  end # class JSON
end # module Visage
