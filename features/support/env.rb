#!/usr/bin/env ruby

require 'pathname'

require 'rspec'
require 'capybara'
require 'capybara/cucumber'
require 'capybara/poltergeist'
require 'delorean'

# Application setup
ENV['RACK_ENV'] = 'test'

root     = Pathname.new(File.dirname(__FILE__)).parent.parent.expand_path

default_config_path = root.join('features/support/config/default')
ENV['CONFIG_PATH']  = default_config_path.to_s
# use a Mock backend, so tests don't depend on any specific backend (e.g. RRD)
ENV['VISAGE_DATA_BACKEND'] = 'Mock'

app_file = root.join('lib/visage-app').to_s
require(app_file)

# http://opensoul.org/blog/archives/2010/05/11/capybaras-eating-cucumbers/
Capybara.app = Rack::Builder.new do
  use Visage::Profiles
  use Visage::Builder
  use Visage::JSON

  run Sinatra::Application
end.to_app

Capybara.javascript_driver = :poltergeist

Capybara.register_driver :poltergeist do |app|
  options = {
    #:debug     => true,
    :js_errors => false,
  }
  Capybara::Poltergeist::Driver.new(app, options)
end

# Cucumber setup
class SinatraWorld
  include Capybara::DSL
end

World do
  SinatraWorld.new
end

After do
  @javascript_time_offset = nil
end
