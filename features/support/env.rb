#!/usr/bin/env ruby

require 'pathname'

@root = Pathname.new(File.dirname(__FILE__)).parent.parent.expand_path
app_file = @root.join('lib/visage-app')

require 'rubygems'
require 'spec/expectations'
require 'rack/test'
require 'webrat'

require app_file
# Force the application name because polyglot breaks the auto-detection logic.
Sinatra::Application.app_file = app_file

Webrat.configure do |config|
  config.mode = :rack
end

class SinatraWorld
  include Rack::Test::Methods
  include Webrat::Methods
  include Webrat::Matchers

  Webrat::Methods.delegate_to_session :response_code, :response_body, :response_headers, :response

  def app
    Rack::Builder.new do
      use Visage::Profiles
      use Visage::Builder
      use Visage::JSON
      run Sinatra::Application
    end
  end
end

World do
  SinatraWorld.new
end

