#!/usr/bin/env ruby

require 'rubygems'
require 'pathname'
$: << Pathname.new(__FILE__).parent.parent.join('lib').to_s
#require 'visage-app'

ENV['RACK_ENV'] = 'test'

RSpec.configure do |config|
  # Use color in STDOUT
  config.color_enabled = true

  # Use color not only in STDOUT but also in pagers and files
  config.tty = true

  # Use the specified formatter
  config.formatter = :documentation # :progress, :html, :textmate

  # Rspec 3 forward compatibility
  config.treat_symbols_as_metadata_keys_with_true_values = true
end

