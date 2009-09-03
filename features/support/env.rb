basedir = File.expand_path(File.join(File.dirname(__FILE__), '..', '..'))
gemdir = File.join(basedir, 'gems')
app_file = File.join(basedir, 'visage')

require 'rubygems'
Gem.clear_paths
Gem.path << gemdir
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

  Webrat::Methods.delegate_to_session :response_code, :response_body

  def app
    Sinatra::Application
  end
end

World do 
  SinatraWorld.new
end

