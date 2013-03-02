#!/usr/bin/env ruby

require 'pathname'

require 'rspec'
require 'capybara'
require 'capybara/cucumber'
require 'capybara/poltergeist'

# Application setup
root     = Pathname.new(File.dirname(__FILE__)).parent.parent.expand_path
app_file = root.join('lib/visage-app').to_s
ENV['CONFIG_PATH']         = root.join('features/support/config/default').to_s
# use a Mock backend, so tests don't depend on any specific backend (e.g. RRD)
ENV['VISAGE_DATA_BACKEND'] = 'Mock'
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
    #:debug => true
    :js_errors => false
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

Before do
  root        = Pathname.new(__FILE__).parent.parent.join('support/config')
  destination = root.join('tmp').join('profiles.yaml')
  FileUtils.rm(destination) if destination.exist?
end
